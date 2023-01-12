{ config, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
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

  fileSystems."/var/lib/postgresql" =
    {
      device = "zroot/data/postgres";
      fsType = "zfs";
      options = [ "x-gvfs-hide" ];
    };


  fileSystems."/home/melinapn" =
    {
      device = "zroot/data/melina";
      fsType = "zfs";
    };

  fileSystems."/home/pedrohlc/Torrents" =
    {
      device = "zroot/data/btdownloads";
      fsType = "zfs";
    };

  fileSystems."/home/pedrohlc/Games" =
    {
      device = "zroot/games/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/C4D7-B910";
      fsType = "vfat";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
