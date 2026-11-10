{ config, lib, options, pkgs, pkgs-unstable, ghosttyPkg, nixGLIntel, ketchPkg, workmuxPkg, ... }:
{
  # Обычный switch не передаёт extraSpecialArgs из flake.nix.
  _module.args = {
    pkgs-unstable = lib.mkDefault (import <nixpkgs-unstable> { inherit (pkgs.stdenv.hostPlatform) system; });
    # Нативный .app для macOS; Linux получает Ghostty и nixGL из flake.nix.
    ghosttyPkg = lib.mkDefault (
      if pkgs.stdenv.hostPlatform.isDarwin then pkgs-unstable.ghostty-bin else null
    );
    nixGLIntel = lib.mkDefault null;
    ketchPkg = lib.mkDefault null;
    # Обычный switch тоже использует ревизию из flake.lock этого репозитория.
    # getFlake нужен только здесь: при --flake пакет приходит через extraSpecialArgs.
    workmuxPkg = lib.mkDefault (
      (builtins.getFlake (toString ./.)).packages.${pkgs.stdenv.hostPlatform.system}.workmuxPkg
    );
  };

  # На macOS обычный `home-manager switch` использует текущего пользователя.
  home.username = lib.mkDefault (if pkgs.stdenv.hostPlatform.isDarwin then builtins.getEnv "USER" else "freak");
  home.homeDirectory = lib.mkDefault (if pkgs.stdenv.hostPlatform.isDarwin then builtins.getEnv "HOME" else "/home/freak");
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  xdg.enable = true;
  targets.genericLinux.enable = pkgs.stdenv.hostPlatform.isLinux;
  # Spotlight не индексирует .app за симлинками в /nix/store.
  # copyApps отсутствует в Home Manager 25.05, используем его только при наличии.
  # Для обновления копий macOS требует разрешение App Management у терминала.
  targets.darwin = lib.optionalAttrs (options.targets.darwin ? copyApps) {
    linkApps.enable = false;
    copyApps.enable = pkgs.stdenv.hostPlatform.isDarwin;
  };

  home.packages = 
    [
      pkgs-unstable.tmux
      pkgs-unstable.zellij
      pkgs-unstable.neovim
      pkgs-unstable.fzf
      pkgs.nil
      pkgs-unstable.ripgrep
      pkgs-unstable.silver-searcher-ng
      pkgs-unstable.fd
      pkgs.yq-go
      pkgs-unstable.zellij
      pkgs-unstable.neovide
      pkgs-unstable.kubectl
      pkgs-unstable.kubectx
      (pkgs-unstable.spoofdpi.overrideAttrs (old: {
        buildInputs = (old.buildInputs or []) ++ [ pkgs-unstable.libpcap ];
      }))
      pkgs-unstable.eza
      pkgs-unstable.kubie
      pkgs-unstable.argocd
      pkgs-unstable.bat
      pkgs-unstable.k9s
      pkgs-unstable.delta
    ]
    ++ lib.optional (ketchPkg != null) ketchPkg
    ++ lib.optional (workmuxPkg != null) workmuxPkg
    ++ (if ghosttyPkg == null then [] else [ ghosttyPkg ])
    ++ (if nixGLIntel == null then [] else [ nixGLIntel ]);

  # Явный .desktop entry для Ghostty — GNOME на Fedora не всегда видит
  # .desktop из nix-профиля. Запускаем через nixGLIntel, который корректно
  # пробрасывает host OpenGL/EGL для Nix-бинарников на не-NixOS системах.
  # GSK_RENDERER=ngl стабильнее умолчательного GL с GTK4 + nixGL.
  home.file.".local/share/applications/com.mitchellh.ghostty.desktop".enable =
    pkgs.stdenv.hostPlatform.isLinux && (ghosttyPkg != null) && (nixGLIntel != null);
  home.file.".local/share/applications/com.mitchellh.ghostty.desktop".text =
    lib.optionalString ((ghosttyPkg != null) && (nixGLIntel != null)) ''
      [Desktop Entry]
      Version=1.0
      Name=Ghostty
      GenericName=Terminal Emulator
      Comment=A terminal emulator
      Exec=env GDK_BACKEND=x11 GSK_RENDERER=ngl ${config.home.profileDirectory}/bin/nixGLIntel ${config.home.profileDirectory}/bin/ghostty --gtk-single-instance=true
      Icon=com.mitchellh.ghostty
      Type=Application
      Categories=System;TerminalEmulator;
      Keywords=terminal;tty;pty;
      StartupNotify=true
      StartupWMClass=com.mitchellh.ghostty
      Terminal=false
      X-GNOME-UsesNotifications=true
    '';

  # Wrapper-скрипт в ~/.local/bin, который запускает ghostty через nixGLIntel
  # с принудительным X11/XWayland backend и стабильным GTK-рендерером
  # (обход EGL-ошибки на Wayland).
  home.file.".local/bin/ghostty" = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && (ghosttyPkg != null) && (nixGLIntel != null)) {
    source = pkgs.writeShellScript "ghostty" ''
      export GDK_BACKEND=x11
      export GSK_RENDERER=ngl
      exec ${nixGLIntel}/bin/nixGLIntel ${ghosttyPkg}/bin/ghostty "$@"
    '';
  };


  # Симлинкуем иконки Ghostty в ~/.local/share/icons, чтобы GNOME их подхватил
  # без перезапуска сессии и независимо от XDG_DATA_DIRS
  home.activation.linkGhosttyIcons = lib.hm.dag.entryAfter ["writeBoundary"] (lib.optionalString (pkgs.stdenv.hostPlatform.isLinux && ghosttyPkg != null) ''
    $DRY_RUN_CMD mkdir -p $HOME/.local/share/icons
    for sz in 16x16 32x32 128x128 256x256 512x512 1024x1024; do
      for variant in "$sz" "$sz"@2; do
        src="${ghosttyPkg}/share/icons/hicolor/$variant/apps/com.mitchellh.ghostty.png"
        if [ -e "$src" ]; then
          dst="$HOME/.local/share/icons/hicolor/$variant/apps"
          $DRY_RUN_CMD mkdir -p "$dst"
          $DRY_RUN_CMD ln -sf "$src" "$dst/com.mitchellh.ghostty.png"
        fi
      done
    done
    # Обновляем кэш иконок
    $DRY_RUN_CMD ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
  '');

  # Импортируем переменные окружения в systemd user session,
  # чтобы GNOME Wayland видел XDG_DATA_DIRS при запуске из launcher
  home.activation.importEnvToSystemd = lib.hm.dag.entryAfter ["linkGhosttyIcons"] (lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
    if command -v systemctl >/dev/null 2>&1; then
      $DRY_RUN_CMD systemctl --user import-environment XDG_DATA_DIRS 2>/dev/null || true
    fi
  '');

  # programs.direnv.enable = true;
  # programs.direnv.nix-direnv.enable = true;
  programs.zsh = {
    enable = true;
    dotDir = if lib.versionAtLeast config.home.version.release "26.05"
      then config.home.homeDirectory else null;
    profileExtra = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      # Локальная интеграция Homebrew/MacPorts/OrbStack вне Nix.
      if [[ -f "$HOME/.zprofile.local" ]]; then
        source "$HOME/.zprofile.local"
      fi
    '';
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };
    shellAliases = {
      gco = "git checkout";
      gcob = "git checkout -b";
      gaa = "git add .";
      gc = "git commit";
      gcam = "git commit --amend";
      gs = "git status";
      glg = "git log --oneline --graph --parents";
      gm = "git merge --no-ff";
      gd = "git diff";
      gb = "git branch";
      ls = "eza";
      claudex = "CLAUDE_CONFIG_DIR=~/.claudex claude";
      claudez = "CLAUDE_CONFIG_DIR=~/.claudez claude";
      nix-shell = "nix-shell --run zsh";
      k = "kubectl";
    }
    // lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux && (ghosttyPkg != null) && (nixGLIntel != null)) {
      ghostty = "GDK_BACKEND=x11 GSK_RENDERER=ngl ${config.home.profileDirectory}/bin/nixGLIntel ${config.home.profileDirectory}/bin/ghostty";
    };
    initContent = ''
      export GIT_SSH=/usr/bin/ssh
      export FZF_DEFAULT_COMMAND='fd --type f'
      export GEM_HOME=$HOME/.gem
      export PATH=$HOME/.local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$HOME/.opencode/bin${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ":$HOME/.local/share/pi-node/node-v22.23.1-linux-x64/bin"}:$PATH
      export EDITOR=nvim
      export OPENCODE_EXPERIMENTAL_MARKDOWN=0
      stty eof undef
      if [[ -n "''${IN_NIX_SHELL:-}" ]]; then
        PROMPT="(nix-shell) $PROMPT"
      fi
      '';
  };

  programs.git = {
    enable = true;
    includes = [{ path = ./gitconfig; }];
  } // (if options.programs.git ? settings then {
    settings.user = {
      name = "Yan Shkurinsky";
      email = "yan.shkurinsky@gmail.com";
    };
  } else {
    # Совместимость с Home Manager 25.05 из flake.nix.
    userName = "Yan Shkurinsky";
    userEmail = "yan.shkurinsky@gmail.com";
  });

  home.file.".config/nvim/lua/packman.lua".source = ./packman.lua;
  home.file.".config/nvim/lua/packer.lua".source = ./packer.nvim/packer.lua;
  home.file.".config/nvim/lua/packer".source = ./packer.nvim/packer;
  home.file.".config/nvim/ftplugin/haskell.vim".source = ./ftplugin/haskell.vim;
  home.file.".config/nvim/init.lua".source = ./init.lua;
  home.file.".tmux.conf".source = ./tmux.conf;
  home.file.".config/alacritty/alacritty.yml".source = ./alacritty.yml;
  home.file.".config/alacritty/alacritty.toml".source = ./alacritty.toml;
  home.file.".config/ghostty/config".source = ./ghostty;
}
