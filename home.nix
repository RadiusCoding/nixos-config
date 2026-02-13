{ config, pkgs, lib, ... }:

{
  home.username = "sage";
  home.homeDirectory = "/home/sage";
  home.stateVersion = "25.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Packages
  home.packages = with pkgs; [
    firefox
    kitty
    feh
    discord
    spotify
    fastfetch
    neovim
    xclip
    wl-clipboard
    direnv
    nodejs_22
    claude-code
    prismlauncher
    cheese
    tailscale
    moonlight-qt
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
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#sagetop";
      config = "nvim ~/nixos-config";
      tempinstall = "nix-shell -p";
    };
  };

  # i3 keybindings for audio
  xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault {
    "XF86AudioRaiseVolume" = "exec --no-startup-id pamixer -i 5";
    "XF86AudioLowerVolume" = "exec --no-startup-id pamixer -d 5";
    "XF86AudioMute" = "exec --no-startup-id pamixer -t";
  };

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
