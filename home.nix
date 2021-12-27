{ config, pkgs, ... }:

{
  home.username = "freak";
  home.homeDirectory = "/home/freak";

  home.stateVersion = "22.05";

  programs.home-manager.enable = true;

  home.packages = [
    pkgs.tmux
    pkgs.neovim
    # pkgs.podman
    # pkgs.runc
    # pkgs.conmon
    # pkgs.skopeo
    # pkgs.slirp4netns
    # pkgs.fuse-overlayfs
    pkgs.fzf
    pkgs.htop
    pkgs.rnix-lsp
    pkgs.xclip
    pkgs.ripgrep
    pkgs.ag
    pkgs.fd
    pkgs.ncdu
    pkgs.haskellPackages.hasktags
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
    };
    shellAliases = {
      gco = "git checkout";
      gcob = "git checkout -b";
      gaa = "git add .";
      gc = "git commit";
      gcam = "git commit --amend";
      gs = "git status";
      glg = "git log --oneline --graph --parents";
    };
    initExtra = ''
      if [ -e /home/freak/.nix-profile/etc/profile.d/nix.sh ]; then . /home/freak/.nix-profile/etc/profile.d/nix.sh; fi
      export PATH=$HOME/.local/bin/:$PATH
      export GIT_SSH=/usr/bin/ssh
      export FZF_DEFAULT_COMMAND='fd --type f'
      '';
  };

  programs.git = {
    enable = true;
    userName = "Yan Shkurinsky";
    userEmail = "yan.shkurinsky@gmail.com";
  };

  home.file.".config/nvim/lua/packman.lua".source = ./packman.lua;
  home.file.".config/nvim/init.lua".source = ./init.lua;
}
