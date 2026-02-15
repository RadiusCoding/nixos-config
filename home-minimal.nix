{ config, pkgs, ... }:

{
  home.username = "sage";
  home.homeDirectory = "/home/sage";
  home.stateVersion = "25.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Packages
  home.packages = with pkgs; [
    fastfetch
    neovim
    direnv
    nodejs_22
    claude-code
    unzip
    zip
    gh
    xterm
    feh
    xclip
  ];

  # Neovim config (symlink only config files, not plugin data)
  home.file.".config/nvim/init.lua".source = ./dotfiles/nvim/init.lua;
  home.file.".config/nvim/lua" = {
    source = ./dotfiles/nvim/lua;
    recursive = true;
  };

  # Wallpapers
  home.file."wallpapers" = {
    source = ./dotfiles/wallpapers;
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

  # i3 config
  home.file.".config/i3/config".source = ./dotfiles/i3/config;

  # Background wallpaper service
  services.random-background = {
    enable = true;
    imageDirectory = "%h/wallpapers";
  };

  # Picom compositor
  services.picom = {
    enable = true;
    shadow = true;
    shadowOffsets = [ (-7) (-7) ];
    shadowOpacity = 0.6;
    settings = {
      corner-radius = 12;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
      ];
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
