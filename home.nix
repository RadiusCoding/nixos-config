{ config, pkgs, ... }:

{
  home.username = "sage";
  home.homeDirectory = "/home/sage";
  home.stateVersion = "25.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Packages
  home.packages = with pkgs; [
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
    polybar
    pywal
    bc
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

  # i3 config
  home.file.".config/i3/config".source = ./dotfiles/i3/config;

  # Polybar config
  home.file.".config/polybar/config.ini".source = ./dotfiles/polybar/config.ini;
  home.file.".config/polybar/launch.sh" = {
    source = ./dotfiles/polybar/launch.sh;
    executable = true;
  };

  # Wallpaper script
  home.file.".config/scripts/wallpaper.sh" = {
    source = ./dotfiles/scripts/wallpaper.sh;
    executable = true;
  };

  # Wallpaper rotation timer (every 30 minutes)
  systemd.user.services.wallpaper-rotate = {
    Unit.Description = "Rotate wallpaper and update colors";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.config/scripts/wallpaper.sh";
      Environment = "PATH=/run/current-system/sw/bin:%h/.nix-profile/bin:/etc/profiles/per-user/sage/bin";
    };
  };
  systemd.user.timers.wallpaper-rotate = {
    Unit.Description = "Rotate wallpaper every 30 minutes";
    Timer = {
      OnCalendar = "*:0/30";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Kitty config
  home.file.".config/kitty/kitty.conf".source = ./dotfiles/kitty/kitty.conf;

  # Picom compositor (glx backend for blur/transparency)
  services.picom = {
    enable = true;
    backend = "glx";
    shadow = true;
    shadowOffsets = [ (-7) (-7) ];
    shadowOpacity = 0.6;
    settings = {
      corner-radius = 12;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
      ];
      blur = {
        method = "dual_kawase";
        strength = 6;
      };
      blur-background-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "class_g = 'slop'"
      ];
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
