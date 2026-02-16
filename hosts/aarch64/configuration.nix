{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader (adjust based on your device)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nixos-arm";
  networking.networkmanager.enable = true;

  # Time and locale
  time.timeZone = "Europe/London";

  # Security
  security.rtkit.enable = true;

  # Audio (PipeWire)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Display and desktop
  services.xserver.enable = true;
  services.xserver.xkb.layout = "gb";
  services.xserver.videoDrivers = [ "modesetting" ];
  services.displayManager.defaultSession = "none+i3";
  services.displayManager.sddm = {
    enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = [
      (pkgs.sddm-astronaut.override { embeddedTheme = "astronaut"; })
    ];
  };

  services.xserver.windowManager.i3 = {
    enable = true;
    package = pkgs.i3;
    extraPackages = with pkgs; [
      dmenu
      i3lock
      xterm
      dex
      xss-lock
      networkmanagerapplet
    ];
  };

  # Services
  services.tailscale.enable = true;
  services.openssh.enable = true;

  # Users
  users.users.sage = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "audio" ];
    initialPassword = "changeme";
  };

  # System-wide programs
  programs.zsh.enable = true;

  # Firefox with Tridactyl extension
  programs.firefox = {
    enable = true;
    policies = {
      ExtensionSettings = {
        "tridactyl.vim@cmcaine.co.uk" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi";
          installation_mode = "force_installed";
        };
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    pamixer
    playerctl
    pavucontrol
    brightnessctl
    (sddm-astronaut.override { embeddedTheme = "astronaut"; })
  ];

  # Environment variables
  environment.sessionVariables = {
    TERMINAL = "xterm";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05";
}
