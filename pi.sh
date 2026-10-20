#!/bin/bash
#
# Universal pi-in-container launcher.
#
# Copy this script into a project and run it. It launches the pi coding agent
# inside an isolated nix-based container with persistent volumes.
#
# Behavior:
#   - Updates pi to the latest version on every run.
#   - Starts PostgreSQL 16 inside the pi container for integration tests.
#   - Optionally syncs skills from a git repository into the first existing
#     .agents/skills directory found under the project root. Does nothing if
#     no .agents directory is found.
#   - Loads .env (if present) and exports its variables to pi.
#   - Runs pi through shell.nix if one is found in the project, otherwise plain.
#   - Resolves the latest ketch release and downloads it when missing/outdated.
#
# Configuration via environment variables (all optional):
#
#   PI_PROJECT_ROOT    Project working tree mounted into the container.
#                      Default: git repository root (else script's directory).
#                      NOTE: when running inside a git worktree, the MOUNTED
#                      tree is the common ancestor that also contains the
#                      shared .git directory (see MOUNT_ROOT below); this value
#                      only selects the working tree (for per-worktree
#                      volume names and shell.nix/.agents lookup).
#   PI_PROJECT_NAME    Name used as a prefix for container volumes (nix store,
#                      root profile, etc.). Each working tree (worktree) gets
#                      its own isolated volumes. Default: basename of the
#                      working tree we launched from.
#   PI_USE_SCRIPT_DIR  Set to 1 to use the script's directory as the project
#                      root instead of the git root.
#   PI_SHELL_NIX       Relative path (within project) to a shell.nix to run pi
#                      through. If unset, auto-detected.
#   PI_GIT_SKILLS      Git URL of a repository containing skills.
#   PI_GIT_SKILLS_DIRS Comma-separated list of directories (relative to repo
#                      root) to copy skills from.
#   PI_KETCH_VERSION   Optional ketch release tag to install (pin). If unset,
#                      the latest GitHub release is resolved on every run.
#   PI_IMAGE           Container image to use. Default: docker.io/nixos/nix.
#   PI_POSTGRES_VOLUME Named volume for PostgreSQL data. Default:
#                      <project-name>-pi-postgres.
#   TEST_DB_PORT       Local PostgreSQL port. Default: 5432.
#   TEST_DB_USER       PostgreSQL superuser. Default: postgres.
#   TEST_DB_PASSWORD   PostgreSQL password. Default: postgres.
#   TEST_DB_NAME       Test database. Default: test_db.
#
# PI_GIT_SKILLS / PI_GIT_SKILLS_DIRS and TEST_DB_* may also live in .env.
# TEST_DB_HOST is always set to 127.0.0.1 because PostgreSQL runs in this
# container.

set -euo pipefail

###############################################################################
# Resolve configuration
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# longest shared parent directory of two absolute paths (used to find a
# mount root that contains BOTH a worktree and the shared .git dir).
common_ancestor() {
  local a="$1" b="$2" IFS=/ result="" i=0
  a="${a%/}"; b="${b%/}"
  local -a aa=($a) bb=($b)
  while [ $i -lt ${#aa[@]} ] && [ $i -lt ${#bb[@]} ] && [ "${aa[$i]}" = "${bb[$i]}" ]; do
    [ -n "${aa[$i]}" ] && result="$result/${aa[$i]}"
    i=$((i + 1))
  done
  [ -z "$result" ] && result="/"
  printf '%s\n' "$result"
}

if [ -n "${PI_PROJECT_ROOT:-}" ]; then
  PROJECT_ROOT="$PI_PROJECT_ROOT"
elif [ -n "${PI_USE_SCRIPT_DIR:-}" ]; then
  PROJECT_ROOT="$SCRIPT_DIR"
else
  # Default: git working tree that contains the CURRENT directory.
  # Crucial for git worktrees: `git rev-parse --show-toplevel` run from the
  # script's own location returns the MAIN repo root, but run from the CWD
  # (inside a worktree) it returns that worktree's root.
  PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [ -z "$PROJECT_ROOT" ] && PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -z "$PROJECT_ROOT" ] && PROJECT_ROOT="$SCRIPT_DIR"
fi

# WORK_ROOT: the working tree (worktree or ordinary repo) we launched from.
# Tied to the launch point: names per-worktree volumes and drives shell.nix /
# .agents / .env lookup, so each branch gets an isolated nix environment.
WORK_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

# MOUNT_ROOT: the tree actually mounted at /project. For an ordinary repo this
# equals WORK_ROOT. For a git worktree it is the common ancestor of the
# worktree root and the shared .git directory (git rev-parse --git-common-dir).
#
# Why: the .git "gitdir:" pointer inside a worktree is an ABSOLUTE host path
# into the main repo's .git/worktrees/<name>. If we only mount the worktree,
# that path does not exist inside the container and every git command fails
# with "fatal: not a git repository". Mounting the common ancestor makes both
# the working tree and the real .git visible. We additionally symlink the
# host's absolute path to /project inside the container (see run_pi) so the
# absolute pointers in .git resolve.
GIT_COMMON_DIR_ABS=""
if _gcd_rel="$(cd "$WORK_ROOT" && git rev-parse --git-common-dir 2>/dev/null)"; then
  case "$_gcd_rel" in
    /*) _gcd_abs_cand="$_gcd_rel" ;;
    *)  _gcd_abs_cand="$WORK_ROOT/$_gcd_rel" ;;
  esac
  GIT_COMMON_DIR_ABS="$(cd "$_gcd_abs_cand" 2>/dev/null && pwd)"
fi
if [ -n "$GIT_COMMON_DIR_ABS" ]; then
  MOUNT_ROOT="$(common_ancestor "$WORK_ROOT" "$(dirname "$GIT_COMMON_DIR_ABS")")"
else
  MOUNT_ROOT="$WORK_ROOT"
fi

# PROJECT_NAME derives volume names. Bind it to the working tree so each
# worktree gets its own isolated nix store + root profile.
PROJECT_NAME="${PI_PROJECT_NAME:-$(basename "$WORK_ROOT")}"

# The host directory the user launched us from, expressed relative to the
# MOUNT ROOT (what gets mounted at /project). pi opens in this directory
# inside the container so launching from e.g. a worktree subdir opens pi at
# /project/<same subdir> -- while the whole common tree is still mounted.
HOST_CWD="$(pwd)"
HOST_CWD_REL="${HOST_CWD#"$MOUNT_ROOT"}"
HOST_CWD_REL="${HOST_CWD_REL#/}"
if [ -z "$HOST_CWD_REL" ] || [ "$HOST_CWD_REL" = "$HOST_CWD" ]; then
  HOST_CWD_REL="."
fi

# The working tree root expressed relative to MOUNT_ROOT (for finding
# shell.nix / .agents inside the worktree, not the main repo).
WORK_ROOT_REL="${WORK_ROOT#"$MOUNT_ROOT"}"
WORK_ROOT_REL="${WORK_ROOT_REL#/}"
if [ -z "$WORK_ROOT_REL" ] || [ "$WORK_ROOT_REL" = "$WORK_ROOT" ]; then
  WORK_ROOT_REL="."
fi

IMAGE="${PI_IMAGE:-docker.io/nixos/nix}"
KETCH_VERSION="${PI_KETCH_VERSION:-}"

NIX_VOLUME="${PROJECT_NAME}-pi-nix"
ROOT_VOLUME="${PROJECT_NAME}-pi-root"
ETC_NIX_VOLUME="${PROJECT_NAME}-pi-etc-nix"
POSTGRES_VOLUME="${PI_POSTGRES_VOLUME:-${PROJECT_NAME}-pi-postgres}"

# Auto-detect container runtime
if command -v podman &> /dev/null; then
  CONTAINER_RUNTIME="podman"
elif command -v docker &> /dev/null; then
  CONTAINER_RUNTIME="docker"
else
  echo "Error: neither podman nor docker found" >&2
  exit 1
fi

###############################################################################
# .env handling
###############################################################################

# Locate .env: prefer the script directory, then the working tree root.
ENV_FILE_PATH=""
for cand in "$SCRIPT_DIR/.env" "$WORK_ROOT/.env"; do
  if [ -f "$cand" ]; then
    ENV_FILE_PATH="$cand"
    break
  fi
done

# Robustly export variables from an env file into the CURRENT (host) shell,
# so this script can read PI_GIT_SKILLS etc. Tolerates `export` prefixes,
# surrounding quotes, comments and blank lines. Does NOT execute arbitrary code.
load_env_file_locally() {
  local file="$1"
  [ -f "$file" ] || return 0
  local line key val
  set +u
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"   # trim leading whitespace
    case "$line" in '' | '#'*) continue ;; esac
    case "$line" in export\ *) line="${line#export }" ; line="${line#"${line%%[![:space:]]*}"}" ;; esac
    case "$line" in *=*) ;; *) continue ;; esac
    key="${line%%=*}"
    val="${line#*=}"
    case "$key" in *[!A-Za-z0-9_]*) continue ;; esac
    case "$val" in
      \"*) val="${val#\"}"; val="${val%\"}" ;;
    esac
    case "$val" in
      \'*) val="${val#\'}"; val="${val%\'}" ;;
    esac
    export "$key=$val"
  done < "$file"
  set -u
}

if [ -n "$ENV_FILE_PATH" ]; then
  echo "Loading env from: $ENV_FILE_PATH"
  load_env_file_locally "$ENV_FILE_PATH"
fi

PI_GIT_SKILLS="${PI_GIT_SKILLS:-}"
PI_GIT_SKILLS_DIRS="${PI_GIT_SKILLS_DIRS:-}"
KETCH_VERSION="${PI_KETCH_VERSION:-$KETCH_VERSION}"

###############################################################################
# Helpers
###############################################################################

volume_is_empty() {
  local vol="$1"
  local entries
  entries=$("$CONTAINER_RUNTIME" run --rm -v "$vol:/vol" "$IMAGE" \
    bash -c 'ls -A /vol 2>/dev/null | wc -l')
  [ "$entries" -eq 0 ]
}

ensure_volume() {
  local vol="$1" label="$2" src="$3"
  if ! "$CONTAINER_RUNTIME" volume inspect "$vol" &>/dev/null; then
    echo "Creating named volume $vol for $label..."
    "$CONTAINER_RUNTIME" volume create "$vol"
  fi

  if volume_is_empty "$vol"; then
    echo "Bootstrapping $label into named volume..."
    "$CONTAINER_RUNTIME" run --rm \
      -v "$vol:/to-copy" \
      "$IMAGE" \
      bash -c "cp -a $src/. /to-copy/"
    echo "$label volume initialized."
  else
    echo "$label volume already initialized."
  fi
}

cleanup_nix_cache() {
  "$CONTAINER_RUNTIME" run --rm \
    -v "$ROOT_VOLUME:/root" \
    "$IMAGE" \
    bash -c '
      cache_dir="/root/.cache/nix"
      mkdir -p "$cache_dir"
      chmod -R 777 "$cache_dir" 2>/dev/null || true
      rm -f "$cache_dir"/binary-cache-v*.sqlite* "$cache_dir"/fetcher-cache-v*.sqlite*
      chmod 755 /root /root/.cache 2>/dev/null || true
    '
}

cleanup_npm_cache() {
  "$CONTAINER_RUNTIME" run --rm \
    -v "$ROOT_VOLUME:/root" \
    "$IMAGE" \
    bash -c '
      npm_dir="/root/.npm"
      rm -rf "$npm_dir" 2>/dev/null || true
      mkdir -p "$npm_dir/_cacache" "$npm_dir/_logs"
      chmod -R 777 "$npm_dir" 2>/dev/null || true
    '
}

ensure_nix_conf() {
  "$CONTAINER_RUNTIME" run --rm \
    -v "$ETC_NIX_VOLUME:/etc/nix" \
    "$IMAGE" \
    bash -c '
      nix_conf="/etc/nix/nix.conf"
      if [ -f "$nix_conf" ]; then
        if ! grep -q "^substituters" "$nix_conf" 2>/dev/null; then
          echo "Adding substituters to nix.conf..."
          cat >> "$nix_conf" <<NIXEOF
substituters = https://cache.nixos.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
NIXEOF
        fi
        if ! grep -q "^extra-experimental-features" "$nix_conf" 2>/dev/null; then
          echo "extra-experimental-features = nix-command flakes" >> "$nix_conf"
        fi
      fi
    '
}

###############################################################################
# Setup steps
###############################################################################

init_volumes() {
  echo "=== Initializing volumes ==="
  ensure_volume "$NIX_VOLUME"    "/nix"     "/nix"
  ensure_volume "$ROOT_VOLUME"   "/root"    "/root"
  ensure_volume "$ETC_NIX_VOLUME" "/etc/nix" "/etc/nix"
  cleanup_nix_cache
  cleanup_npm_cache
  ensure_nix_conf
}

setup_ketch() {
  echo "=== Setting up ketch ==="

  local setup_script
  setup_script=$(mktemp /tmp/ketch-setup-XXXXXX.sh)
  trap 'rm -f "$setup_script"' RETURN

  cat > "$setup_script" <<'EOF'
#!/bin/bash
set -e

requested_version="${PI_KETCH_VERSION:-}"
version_file=/root/.local/share/ketch/version
ketch_bin=/root/.local/bin/ketch

resolve_latest_version() {
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/1broseidon/ketch/releases/latest \
    | sed -n "s/.*\"tag_name\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
    | head -n 1
}

installed_version=""
if [ -f "$version_file" ]; then
  installed_version="$(tr -d "[:space:]" < "$version_file")"
elif [ -x "$ketch_bin" ]; then
  installed_version="$($ketch_bin --version 2>/dev/null \
    | sed -n "s/.*\(v\{0,1\}[0-9][0-9.]*\).*/\1/p" \
    | head -n 1 \
    || true)"
  if [ -n "$installed_version" ]; then
    case "$installed_version" in v*) ;; *) installed_version="v$installed_version" ;; esac
  fi
fi

if [ -n "$requested_version" ]; then
  ketch_version="$requested_version"
  echo "Using pinned ketch release: $ketch_version"
else
  echo "Resolving latest ketch release..."
  if ! ketch_version="$(resolve_latest_version)" || [ -z "$ketch_version" ]; then
    if [ -x "$ketch_bin" ]; then
      echo "Warning: failed to resolve latest ketch release; keeping installed ketch${installed_version:+ ($installed_version)}." >&2
      exit 0
    fi
    echo "Error: failed to resolve latest ketch release and ketch is not installed." >&2
    exit 1
  fi
  echo "Latest ketch release: $ketch_version"
fi

case "$ketch_version" in v*) ;; *) ketch_version="v$ketch_version" ;; esac

if [ -x "$ketch_bin" ] && [ "$installed_version" = "$ketch_version" ]; then
  echo "ketch $ketch_version already installed."
  exit 0
fi

if [ -x "$ketch_bin" ]; then
  echo "Updating ketch${installed_version:+ from $installed_version} to $ketch_version..."
else
  echo "Installing ketch $ketch_version..."
fi

arch=$(uname -m)
case "$arch" in
  x86_64)  ketch_arch="linux_x86_64" ;;
  aarch64) ketch_arch="linux_arm64" ;;
  *)
    echo "Warning: unsupported arch $arch for ketch, skipping" >&2
    exit 0
    ;;
esac

ketch_url="https://github.com/1broseidon/ketch/releases/download/${ketch_version}/ketch_${ketch_version#v}_${ketch_arch}.tar.gz"

echo "Fetching $ketch_url ..."
tmpdir="$(mktemp -d)"
trap "rm -rf \"$tmpdir\"" EXIT
mkdir -p /root/.local/bin /root/.local/share/ketch
curl -fsSL "$ketch_url" -o "$tmpdir/ketch.tar.gz"
tar xzf "$tmpdir/ketch.tar.gz" -C "$tmpdir"
install -m 0755 "$tmpdir/ketch" "$ketch_bin"
printf "%s\n" "$ketch_version" > "$version_file"
echo "ketch $ketch_version setup complete."
EOF

  "$CONTAINER_RUNTIME" run --rm \
    -v "$NIX_VOLUME:/nix" \
    -v "$ROOT_VOLUME:/root" \
    -v "$ETC_NIX_VOLUME:/etc/nix" \
    -v "$setup_script:/setup-ketch.sh:ro" \
    -e "PI_KETCH_VERSION=$KETCH_VERSION" \
    "$IMAGE" \
    bash -c 'nix-shell -p curl gnused gnutar gzip coreutils --run "bash /setup-ketch.sh"'
}

setup_nix_tools() {
  echo "=== Setting up nix tools (fd, ripgrep, neovim, python3, nodejs, PostgreSQL 16) ==="
  "$CONTAINER_RUNTIME" run --rm \
    -v "$NIX_VOLUME:/nix" \
    -v "$ROOT_VOLUME:/root" \
    -v "$ETC_NIX_VOLUME:/etc/nix" \
    "$IMAGE" \
    bash -c '
      export PATH="/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

      # Ensure nixpkgs-unstable alias exists
      if [ ! -e /root/.nix-defexpr/channels/nixpkgs-unstable ]; then
        ln -sf /nix/var/nix/profiles/per-user/root/channels/nixpkgs /root/.nix-defexpr/channels/nixpkgs-unstable
      fi

      for pkg in fd ripgrep neovim python3 nodejs postgresql_16; do
        bin="$pkg"
        [ "$pkg" = "ripgrep" ] && bin="rg"
        [ "$pkg" = "neovim" ] && bin="nvim"
        [ "$pkg" = "nodejs" ] && bin="node"
        [ "$pkg" = "postgresql_16" ] && bin="postgres"

        needs_install=false
        command -v "$bin" &> /dev/null || needs_install=true
        if [ "$pkg" = "postgresql_16" ] && ! postgres --version 2>/dev/null | grep -q "PostgreSQL) 16\."; then
          needs_install=true
        fi
        if $needs_install; then
          echo "Installing $pkg via nix-env..."
          nix-env -iA "nixpkgs.$pkg" 2>/dev/null || nix-env -f "<nixpkgs>" -iA "$pkg"
        fi
      done
      echo "nix tools ready."
    '
}

setup_pi() {
  echo "=== Setting up pi agent ==="
  echo "Installing/updating pi coding agent..."

  local setup_script
  setup_script=$(mktemp /tmp/pi-setup-XXXXXX.sh)
  trap 'rm -f "$setup_script"' RETURN

  cat > "$setup_script" <<'EOF'
#!/bin/bash
set -e
mkdir -p /root/.npm-global
npm config set prefix "/root/.npm-global"
export PATH="/root/.npm-global/bin:$PATH"

# Force-clean the old package (including temp dirs from interrupted installs)
rm -rf /root/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent 2>/dev/null || true
rm -rf /root/.npm-global/lib/node_modules/@earendil-works/.pi-coding-agent-* 2>/dev/null || true
rm -rf /root/.npm-global/lib/node_modules/@mariozechner/pi-coding-agent 2>/dev/null || true
rm -rf /root/.npm-global/lib/node_modules/@mariozechner/.pi-coding-agent-* 2>/dev/null || true
# Clean npm metadata cache so @latest resolves to the newest published version
npm cache clean --force 2>/dev/null || true
npm install -g --force @earendil-works/pi-coding-agent@latest

# Ensure nixpkgs-unstable channel alias exists (project shell.nix may need it)
if [ ! -e /root/.nix-defexpr/channels/nixpkgs-unstable ]; then
  echo "Creating nixpkgs-unstable channel alias..."
  ln -sf /nix/var/nix/profiles/per-user/root/channels/nixpkgs /root/.nix-defexpr/channels/nixpkgs-unstable
fi
EOF

  "$CONTAINER_RUNTIME" run --rm \
    -v "$NIX_VOLUME:/nix" \
    -v "$ROOT_VOLUME:/root" \
    -v "$ETC_NIX_VOLUME:/etc/nix" \
    -v "$setup_script:/setup-pi.sh:ro" \
    "$IMAGE" \
    bash -c 'nix-shell -p nodejs --run "bash /setup-pi.sh"'

  echo "pi setup complete."
}

sync_git_skills() {
  if [ -z "$PI_GIT_SKILLS" ] || [ -z "$PI_GIT_SKILLS_DIRS" ]; then
    return 0
  fi

  echo "=== Syncing skills from $PI_GIT_SKILLS ==="

  # Clone on the HOST: it already has ssh-agent, known_hosts, git and keys.
  if ! command -v git &> /dev/null; then
    echo "Error: git is not installed on the host, but PI_GIT_SKILLS requires it." >&2
    echo "Install git, or provide skills another way." >&2
    exit 1
  fi

  local tmp_repo
  tmp_repo="$(mktemp -d)"
  trap 'rm -rf "$tmp_repo"' RETURN

  echo "Cloning $PI_GIT_SKILLS (master) on host..."
  git clone --depth 1 -b master "$PI_GIT_SKILLS" "$tmp_repo"

  # Find an existing .agents directory anywhere under the WORKING TREE
  # (the worktree we launched from, not the main repo). Skills are copied
  # into <found>/.agents/skills. If none exists, do nothing.
  local agents_root
  agents_root="$(find "$WORK_ROOT" -type d -name .agents -print -quit 2>/dev/null || true)"
  if [ -z "$agents_root" ]; then
    echo "No .agents directory found; skipping skills sync." >&2
    return 0
  fi
  local target_dir="$agents_root/skills"
  echo "Target skills dir: $target_dir"
  mkdir -p "$target_dir"

  local IFS=','
  for dir in $PI_GIT_SKILLS_DIRS; do
    dir="${dir## }"; dir="${dir%% }"
    [ -n "$dir" ] || continue
    local src="$tmp_repo/$dir"
    if [ ! -d "$src" ]; then
      echo "Warning: skills dir not found in repo: $dir" >&2
      continue
    fi
    for skill in "$src"/*/; do
      [ -d "$skill" ] || continue
      local name
      name="$(basename "$skill")"
      echo "  -> $name (from $dir)"
      rm -rf "$target_dir/$name"
      cp -a "$skill" "$target_dir/$name"
    done
  done

  echo "Git skills synced."
}

# Resolve PI_SHELL_NIX (relative path within the working tree) or auto-detect.
# The result is expressed relative to MOUNT_ROOT (what is mounted at /project)
# so that it points at the worktree's OWN shell.nix, not the main repo's.
resolve_shell_nix() {
  local found_abs=""

  if [ -n "${PI_SHELL_NIX:-}" ]; then
    # User-supplied path is relative to the working tree.
    found_abs="$WORK_ROOT/$PI_SHELL_NIX"
  elif [ -f "$WORK_ROOT/shell.nix" ]; then
    found_abs="$WORK_ROOT/shell.nix"
  else
    # Search one level deep (e.g. haskell/shell.nix) under the working tree.
    found_abs="$(find "$WORK_ROOT" -mindepth 2 -maxdepth 2 -name shell.nix -type f -print -quit 2>/dev/null || true)"
  fi

  if [ -z "$found_abs" ] || [ ! -f "$found_abs" ]; then
    SHELL_NIX_REL=""
    return 0
  fi

  # Express the absolute host path relative to MOUNT_ROOT.
  SHELL_NIX_REL="${found_abs#"$MOUNT_ROOT"}"
  SHELL_NIX_REL="${SHELL_NIX_REL#/}"
  # If for some reason the path is outside MOUNT_ROOT, fall back to the
  # working-tree-relative form so it still resolves inside the container.
  if [ "$SHELL_NIX_REL" = "$found_abs" ]; then
    SHELL_NIX_REL="${WORK_ROOT_REL%.}/$(basename "$found_abs")"
    SHELL_NIX_REL="${SHELL_NIX_REL#./}"
  fi
}

run_pi() {
  echo "=== Starting pi dev container ==="
  echo "Working tree: $WORK_ROOT"
  echo "Mount root:   $MOUNT_ROOT  (mounted at /project)"
  echo "Nix volume:   $NIX_VOLUME  (isolated per working tree)"
  [ "$WORK_ROOT" != "$MOUNT_ROOT" ] && echo "Mode: git worktree (host path symlinked so git absolute pointers resolve)"

  resolve_shell_nix

  local run_script
  run_script=$(mktemp /tmp/pi-run-XXXXXX.sh)
  trap 'rm -f "$run_script"' RETURN

  local shell_nix_rel="$SHELL_NIX_REL"
  local script_dir_rel="${SCRIPT_DIR#"$MOUNT_ROOT"}"
  script_dir_rel="${script_dir_rel#/}"
  [ -z "$script_dir_rel" ] && script_dir_rel="."
  local postgres_init_dump="/project/$script_dir_rel/init_dump.sql"
  local pi_cmd
  # pi opens in the SAME subdirectory the user launched from on the host
  # (expressed relative to MOUNT_ROOT). The whole common tree is mounted at
  # /project, so this just changes the starting cwd inside pi.
  local workdir_rel="$HOST_CWD_REL"
  if [ -n "$shell_nix_rel" ]; then
    echo "Using shell.nix: $shell_nix_rel"
    # nix resolves relative imports in shell.nix relative to the .nix file's
    # own location, not the cwd -- so we can safely cd to the user's host cwd.
    pi_cmd="cd \"/project/$workdir_rel\" && nix-shell \"/project/$shell_nix_rel\" --run \"exec pi\""
  else
    echo "No shell.nix found; launching pi directly."
    pi_cmd="cd \"/project/$workdir_rel\" && export PATH=\"/root/.npm-global/bin:$PATH\"; exec pi"
  fi

  # Whether we have an env file to load inside the container.
  local has_env=0
  [ -n "$ENV_FILE_PATH" ] && has_env=1

  cat > "$run_script" <<EOF
#!/bin/bash
set -euo pipefail
set +H

export PATH="/root/.npm-global/bin:/root/.local/bin:/root/.nix-profile/bin:\$PATH"
export HOME=/root
export EDITOR=nvim
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# --- Load .env into the environment pi will see ---
if [ -f /container.env ]; then
  set +e +u
  set -a
  # shellcheck disable=SC1091
  . /container.env
  set +a
  set -e -u
fi

# PostgreSQL runs in this container, so tests must always connect locally.
export TEST_DB_HOST=127.0.0.1
export TEST_DB_PORT="\${TEST_DB_PORT:-5432}"
export TEST_DB_USER="\${TEST_DB_USER:-postgres}"
export TEST_DB_PASSWORD="\${TEST_DB_PASSWORD:-postgres}"
export TEST_DB_NAME="\${TEST_DB_NAME:-test_db}"

# Ensure nixpkgs-unstable alias exists
if [ ! -e /root/.nix-defexpr/channels/nixpkgs-unstable ]; then
  ln -sf /nix/var/nix/profiles/per-user/root/channels/nixpkgs /root/.nix-defexpr/channels/nixpkgs-unstable
fi

# Ensure binary cache is configured (in case nix.conf was reset)
if ! grep -q "^substituters" /etc/nix/nix.conf 2>/dev/null; then
  echo "substituters = https://cache.nixos.org" >> /etc/nix/nix.conf
  echo "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" >> /etc/nix/nix.conf
fi
if ! grep -q "^extra-experimental-features" /etc/nix/nix.conf 2>/dev/null; then
  echo "extra-experimental-features = nix-command flakes" >> /etc/nix/nix.conf
fi

# Remove stale SQLite cache files and ensure nix cache dir is writable
mkdir -p /root/.cache/nix
chmod -R 777 /root/.cache/nix 2>/dev/null || true
rm -f /root/.cache/nix/binary-cache-v*.sqlite* /root/.cache/nix/fetcher-cache-v*.sqlite*

# Ensure /root is traversable and pi session dir is writable (nixbld users need access)
chmod 755 /root 2>/dev/null || true
mkdir -p /root/.pi/agent/sessions
chmod -R 777 /root/.pi 2>/dev/null || true

# Make the host's absolute path to the mounted tree resolve to /project
# inside the container. This is essential for git worktrees: the .git
# "gitdir:" pointer inside a worktree is an ABSOLUTE host path into the
# main repo's .git/worktrees/<name>. Without this symlink, git commands
# fail with "fatal: not a git repository" because that absolute path does
# not otherwise exist in the container.
mount_host='$MOUNT_ROOT'
if [ -n "\$mount_host" ] && [ "\$mount_host" != "/" ]; then
  parent="\${mount_host%/*}"
  [ "\$parent" = "\$mount_host" ] && parent="/"
  mkdir -p "\$parent"
  ln -sfn /project "\$mount_host"
fi

# --- Start PostgreSQL in the same container as pi ---
ensure_writable_etc_file() {
  local file="\$1"
  local tmp

  # The nix image may expose /etc/passwd and /etc/group as symlinks into the
  # read-only nix store. Replace such symlinks with local copies before adding
  # the runtime-only postgres account.
  if [ -L "\$file" ]; then
    tmp="\$(mktemp)"
    cp -p "\$file" "\$tmp"
    rm "\$file"
    cp -p "\$tmp" "\$file"
    rm -f "\$tmp"
  fi
}

uid_exists() {
  local needle="\$1"
  local _name _password uid _rest
  while IFS=: read -r _name _password uid _rest; do
    [ "\$uid" = "\$needle" ] && return 0
  done < /etc/passwd
  return 1
}

gid_exists() {
  local needle="\$1"
  local _name _password gid _rest
  while IFS=: read -r _name _password gid _rest; do
    [ "\$gid" = "\$needle" ] && return 0
  done < /etc/group
  return 1
}

pick_free_uid() {
  local id="\$1"
  while uid_exists "\$id"; do
    id=\$((id + 1))
  done
  printf '%s\n' "\$id"
}

pick_free_gid() {
  local id="\$1"
  while gid_exists "\$id"; do
    id=\$((id + 1))
  done
  printf '%s\n' "\$id"
}

postgres_gid() {
  local name _password gid _rest
  while IFS=: read -r name _password gid _rest; do
    if [ "\$name" = postgres ]; then
      printf '%s\n' "\$gid"
      return 0
    fi
  done < /etc/group
  return 1
}

ensure_postgres_user() {
  local pg_uid pg_gid

  if ! grep -q '^postgres:' /etc/group; then
    ensure_writable_etc_file /etc/group
    pg_gid="\$(pick_free_gid 999)"
    echo "postgres:x:\$pg_gid:" >> /etc/group
  else
    pg_gid="\$(postgres_gid)"
  fi

  if ! grep -q '^postgres:' /etc/passwd; then
    ensure_writable_etc_file /etc/passwd
    pg_uid="\$(pick_free_uid 999)"
    echo "postgres:x:\$pg_uid:\$pg_gid:PostgreSQL:/var/lib/postgresql:/bin/sh" >> /etc/passwd
  fi
}

start_postgres() {
  local pgdata=/var/lib/postgresql/data
  local pglog="\$pgdata/postgresql.log"
  local pwfile

  echo "=== Starting local PostgreSQL 16 ==="
  ensure_postgres_user
  mkdir -p "\$pgdata" /run/postgresql
  chown postgres:postgres "\$pgdata" /run/postgresql

  if [ ! -s "\$pgdata/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data volume..."
    pwfile="\$(mktemp)"
    printf '%s' "\$TEST_DB_PASSWORD" > "\$pwfile"
    chown postgres:postgres "\$pwfile"
    chroot --userspec=postgres:postgres / initdb \
      -D "\$pgdata" \
      --username="\$TEST_DB_USER" \
      --pwfile="\$pwfile" \
      --auth-local=trust \
      --auth-host=scram-sha-256
    rm -f "\$pwfile"
  fi

  # The previous ephemeral pi container was stopped without pg_ctl, so its
  # PID file may remain in the persistent volume.
  rm -f "\$pgdata/postmaster.pid"

  if ! chroot --userspec=postgres:postgres / pg_ctl \
      -D "\$pgdata" \
      -l "\$pglog" \
      -o "-h 127.0.0.1 -p \$TEST_DB_PORT" \
      -w start; then
    echo "PostgreSQL failed to start:" >&2
    tail -n 50 "\$pglog" >&2 || true
    exit 1
  fi

  export PGHOST="\$TEST_DB_HOST"
  export PGPORT="\$TEST_DB_PORT"
  export PGUSER="\$TEST_DB_USER"
  export PGPASSWORD="\$TEST_DB_PASSWORD"

  if ! psql -d postgres -Atc "SELECT datname FROM pg_database" | grep -Fxq "\$TEST_DB_NAME"; then
    echo "Creating database \$TEST_DB_NAME..."
    createdb --maintenance-db=postgres "\$TEST_DB_NAME"
  fi

  if [ -f "$postgres_init_dump" ] && \
      [ "\$(psql -d "\$TEST_DB_NAME" -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name = 'api'")" != "1" ]; then
    echo "Applying init_dump.sql..."
    psql -d "\$TEST_DB_NAME" < "$postgres_init_dump"
    echo "[OK] Schema applied."
  fi

  echo "[OK] PostgreSQL is ready at 127.0.0.1:\$TEST_DB_PORT/\$TEST_DB_NAME."
}

start_postgres

echo "=== Pi dev container ready ==="
echo "Project: /project"
echo ""

# --- Run pi ---
$pi_cmd
EOF

  chmod +x "$run_script"

  # Build volume flags. Mount the common ancestor of the working tree and
  # the shared .git dir (MOUNT_ROOT) so the whole repo -- including .git and
  # sibling worktrees -- is visible. Per-worktree isolation comes from the
  # NIX/ROOT volumes (named after the working tree, see PROJECT_NAME).
  local -a run_volumes=(
    -v "$NIX_VOLUME:/nix"
    -v "$ROOT_VOLUME:/root"
    -v "$ETC_NIX_VOLUME:/etc/nix"
    -v "$POSTGRES_VOLUME:/var/lib/postgresql/data"
    -v "$MOUNT_ROOT:/project"
    -v "$run_script:/run-pi.sh:ro"
  )
  # Mount the .env file (if any) at a fixed path and load it inside the script.
  if [ "$has_env" -eq 1 ]; then
    run_volumes+=(-v "$ENV_FILE_PATH:/container.env:ro")
  fi

  exec "$CONTAINER_RUNTIME" run -it --rm \
    "${run_volumes[@]}" \
    -w "/project/$workdir_rel" \
    "$IMAGE" \
    bash /run-pi.sh
}

###############################################################################
# Main
###############################################################################

main() {
  init_volumes
  setup_ketch
  setup_nix_tools
  setup_pi
  sync_git_skills
  run_pi
}

main "$@"
