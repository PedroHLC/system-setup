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

  fileSystems."/var/lib/postgresql" =
    {
      device = "zroot/data/postgres";
      fsType = "zfs";
      options = [ "x-gvfs-hide" ];
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
      device = "/dev/disk/by-uuid/E8A9-EF09";
      fsType = "vfat";
    };

  swapDevices = [
    { device = "/dev/disk/by-uuid/f393bc15-d419-46f0-b637-47c8e155778d"; }
    { device = "/dev/disk/by-uuid/547eedc8-1822-436a-8ae9-4dd840231f26"; }
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
