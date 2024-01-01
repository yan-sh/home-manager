{ config, ... }:

let
  pkgs = import <nixpkgs> {};
  pkgs-unstable = import <nixpkgs-unstable> {};
in
{
  home.username = "yanshkurinsky";
  home.homeDirectory = "/Users/yanshkurinsky";
  home.stateVersion = "23.05";

  programs.home-manager.enable = true;

  home.packages = 
    [
      pkgs.tmux
      pkgs-unstable.neovim
      pkgs.fzf
      # pkgs.htop
      pkgs.rnix-lsp
      # pkgs.xclip
      pkgs.ripgrep
      pkgs.silver-searcher
      pkgs.fd
      # pkgs.ncdu
      # pkgs.httpie
      # pkgs.jq
      # pkgs.rustup
      # pkgs.rust-analyzer
      # pkgs.direnv
      # pkgs.gnvim
      # pkgs.neovide
      # pkgs-unstable.obsidian
      pkgs-unstable.zellij
      # pkgs-unstable.podman
    ];

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
    };
    initExtra = ''
      export GIT_SSH=/usr/bin/ssh
      export FZF_DEFAULT_COMMAND='fd --type f'
      export PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH:$HOME/.ghcup/bin:$HOME/.cabal/bin
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
}
