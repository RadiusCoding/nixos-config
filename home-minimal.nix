{ config, pkgs, lib, ... }:

{
  home.username = "sage";
  home.homeDirectory = "/home/sage";
  home.stateVersion = "25.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Minimal packages (no GUI)
  home.packages = with pkgs; [
    fastfetch
    neovim
    direnv
    nodejs_22
    claude-code
    unzip
    zip
    gh
  ];

  # Neovim config (symlink only config files, not plugin data)
  home.file.".config/nvim/init.lua".source = ./dotfiles/nvim/init.lua;
  home.file.".config/nvim/lua" = {
    source = ./dotfiles/nvim/lua;
    recursive = true;
  };

  # Git
  programs.git = {
    enable = true;
    userName = "Will Fort";
    userEmail = "willf@williamfort.click";
  };

  # Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "sudo"
        "history"
        "direnv"
      ];
    };

    shellAliases = {
      ll = "ls -la";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#nixos-arm";
      config = "nvim ~/nixos-config";
      tempinstall = "nix-shell -p";
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
