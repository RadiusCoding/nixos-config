{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "sagetop";
  networking.networkmanager.enable = true;

  # Time and locale
  time.timeZone = "Europe/London";

  # Security
  security.rtkit.enable = true;

  # Audio (PipeWire)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Display and desktop
  services.xserver.enable = true;
  services.xserver.xkb.layout = "gb";
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
      i3status
      i3lock
      kitty
    ];
  };

  # Services
  services.tailscale.enable = true;

  # Users
  users.users.sage = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "audio" ];
    initialPassword = "changeme";
    packages = with pkgs; [
      tree
    ];
  };

  # System-wide programs
  programs.zsh.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    xfce.thunar
    (sddm-astronaut.override { embeddedTheme = "astronaut"; })
    pamixer
    playerctl
    pavucontrol
    brightnessctl
  ];

  # Environment variables
  environment.sessionVariables = {
    TERMINAL = "kitty";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05";
}
