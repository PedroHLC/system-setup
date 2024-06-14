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
      device = "/dev/disk/by-uuid/AD2E-1931";
      fsType = "vfat";
    };

  #fileSystems."/mnt" =
  #{
  #  device = "/dev/zvol/zroot/data/ext4";
  #  fsType = "ext4";
  #  options = [ "x-gvfs-hide" ];
  #};

  swapDevices = [
    { device = "/dev/disk/by-uuid/34e7ca32-40da-4742-9bc5-7d055ece3002"; }
    # { device = "/dev/disk/by-uuid/2d9a907f-767c-4424-b0c5-603c1d5d018e"; }
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
