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
      device = "zroot/ROOT/nixos";
      fsType = "zfs";
    };

  fileSystems."/home" =
    {
      device = "zroot/data/home";
      fsType = "zfs";
    };

  fileSystems."/home/pedrohlc/.cache/btdownloads" =
    {
      device = "zroot/data/btdownloads";
      fsType = "zfs";
    };

  fileSystems."/home/pedrohlc/.local/share/Steam/steamapps/common" =
    {
      device = "zroot/games/steam";
      fsType = "zfs";
    };

  fileSystems."/etc/NetworkManager/system-connections" =
    {
      device = "zroot/data/connections";
      fsType = "zfs";
    };

  fileSystems."/etc/ssh" =
    {
      device = "zroot/data/ssh";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/CE37-1D5C";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/11da3712-e7a2-442b-9077-c74d72c84a95"; }
      { device = "/dev/disk/by-uuid/2340157f-8dd9-493c-8db3-df3eac3031b6"; }];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
