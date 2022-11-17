{ config, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "zroot/ROOT/empty";
      fsType = "zfs";
      neededForBoot = true;
    };

  fileSystems."/nix" =
    {
      device = "zroot/ROOT/nix";
      fsType = "zfs";
      neededForBoot = true;
    };

  fileSystems."/var/persistent" =
    {
      device = "zroot/data/persistent";
      fsType = "zfs";
      neededForBoot = true;
    };

  fileSystems."/var/residues" =
    # Like "persistent", but for cache and stuff I'll never need to backup.
    {
      device = "zroot/ROOT/residues";
      fsType = "zfs";
      neededForBoot = true;
    };

  fileSystems."/home/pedrohlc/Games" =
    {
      device = "zroot/games/home";
      fsType = "zfs";
      options = [ "x-gvfs-hide" ];
    };

  fileSystems."/home/pedrohlc/Torrents" =
    {
      device = "zroot/data/btdownloads";
      fsType = "zfs";
      options = [ "x-gvfs-hide" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/AD2E-1931";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/bf97699c-1ac8-45dd-bfa1-07fbf9a75e32"; }
      { device = "/dev/disk/by-uuid/b29154e2-96dc-4771-9692-143995e9e4fe"; }];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
