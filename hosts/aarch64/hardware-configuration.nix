# Placeholder - replace with generated hardware-configuration.nix from the actual device
# Run: nixos-generate-config --show-hardware-config > hardware-configuration.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # TODO: Replace this with actual hardware config from the device
  # boot.initrd.availableKernelModules = [ ];
  # boot.initrd.kernelModules = [ ];
  # boot.kernelModules = [ ];
  # boot.extraModulePackages = [ ];

  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/XXXX";
  #   fsType = "ext4";
  # };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
