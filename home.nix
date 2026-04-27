{ config, lib, pkgs ? import <nixpkgs> {}, pkgs-unstable ? import <nixpkgs-unstable> {}, beads ? null, ghosttyPkg ? null, nixGLIntel ? null, ... }:
{
  home.username = "freak";
  home.homeDirectory = "/home/freak";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  xdg.enable = true;
  targets.genericLinux.enable = true;

  home.packages = 
    [
      pkgs-unstable.tmux
      pkgs-unstable.neovim
      pkgs-unstable.fzf
      pkgs.nil
      pkgs-unstable.ripgrep
      pkgs-unstable.silver-searcher
      pkgs-unstable.fd
      pkgs.yq-go
      pkgs-unstable.zellij
      pkgs-unstable.neovide
      pkgs-unstable.kubectl
      pkgs-unstable.kubectx
      pkgs-unstable.spoofdpi
      pkgs-unstable.eza
      pkgs-unstable.kubie
      pkgs-unstable.codex
      pkgs-unstable.argocd
    ]
    ++ (if ghosttyPkg == null then [] else [ ghosttyPkg ])
    ++ (if nixGLIntel == null then [] else [ nixGLIntel ]);
    # ++ (if beads == null then [] else [ beads ]);

  # Явный .desktop entry для Ghostty — GNOME на Fedora не всегда видит
  # .desktop из nix-профиля. Запускаем через nixGLIntel, который корректно
  # пробрасывает host OpenGL/EGL для Nix-бинарников на не-NixOS системах.
  home.file.".local/share/applications/com.mitchellh.ghostty.desktop".text =
    lib.optionalString ((ghosttyPkg != null) && (nixGLIntel != null)) ''
      [Desktop Entry]
      Version=1.0
      Name=Ghostty
      GenericName=Terminal Emulator
      Comment=A terminal emulator
      Exec=env GDK_BACKEND=x11 ${config.home.profileDirectory}/bin/nixGLIntel ${config.home.profileDirectory}/bin/ghostty --gtk-single-instance=true
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
  # с принудительным X11/XWayland backend (обход EGL-ошибки на Wayland).
  home.file.".local/bin/ghostty".source =
    if (ghosttyPkg != null) && (nixGLIntel != null)
    then pkgs.writeShellScript "ghostty" ''
      export GDK_BACKEND=x11
      exec ${nixGLIntel}/bin/nixGLIntel ${ghosttyPkg}/bin/ghostty "$@"
    ''
    else null;


  # Симлинкуем иконки Ghostty в ~/.local/share/icons, чтобы GNOME их подхватил
  # без перезапуска сессии и независимо от XDG_DATA_DIRS
  home.activation.linkGhosttyIcons = lib.hm.dag.entryAfter ["writeBoundary"] (lib.optionalString (ghosttyPkg != null) ''
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
  home.activation.importEnvToSystemd = lib.hm.dag.entryAfter ["linkGhosttyIcons"] ''
    if command -v systemctl >/dev/null 2>&1; then
      $DRY_RUN_CMD systemctl --user import-environment XDG_DATA_DIRS 2>/dev/null || true
    fi
  '';

  # programs.direnv.enable = true;
  # programs.direnv.nix-direnv.enable = true;
  programs.zsh = {
    enable = true;
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
    }
    // lib.optionalAttrs ((ghosttyPkg != null) && (nixGLIntel != null)) {
      ghostty = "GDK_BACKEND=x11 ${config.home.profileDirectory}/bin/nixGLIntel ${config.home.profileDirectory}/bin/ghostty";
    };
    initContent = ''
      export GIT_SSH=/usr/bin/ssh
      export FZF_DEFAULT_COMMAND='fd --type f'
      export GEM_HOME=$HOME/.gem
      export PATH=$HOME/.local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$HOME/.opencode/bin:$PATH
      export EDITOR=nvim
      export OPENCODE_EXPERIMENTAL_MARKDOWN=0
      '';
  };

  programs.git = {
    enable = true;
    userName = "Yan Shkurinsky";
    userEmail = "yan.shkurinsky@gmail.com";
  };

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
