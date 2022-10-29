{ config, lib, modulesPath, ... }:

let
  zfsFs = path:
    {
      device = "zroot/${path}";
      fsType = "zfs";
    };
in
{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Legacy
  fileSystems."/" = zfsFs "ROOT/default";
  fileSystems."/home" = zfsFs "data/home";
  fileSystems."/home/pedrohlc/.cache/btdownloads" = zfsFs "data/btdownloads";

  # System's filesystem
  fileSystems."/mnt" = zfsFs "ROOT/empty";
  fileSystems."/mnt/nix" = zfsFs "ROOT/nix";
  fileSystems."/mnt/var/cache" = zfsFs "ROOT/var-cache";
  fileSystems."/mnt/var/log" = zfsFs "ROOT/var-log";

  # System's data
  fileSystems."/mnt/etc/NetworkManager/system-connections" = zfsFs "data/connections";
  fileSystems."/mnt/etc/nixos" = zfsFs "data/setup";
  fileSystems."/mnt/etc/ssh" = zfsFs "data/sshd";
  fileSystems."/mnt/var/lib/bluetooth" = zfsFs "data/bluetooth";
  fileSystems."/mnt/var/lib/containers" = zfsFs "data/containers";
  fileSystems."/mnt/var/lib/flatpak" = zfsFs "data/flatpak";
  fileSystems."/mnt/var/lib/systemd" = zfsFs "data/systemd";
  fileSystems."/mnt/var/lib/upower" = zfsFs "data/upower";

  # Root's home
  fileSystems."/mnt/root/.cache" = zfsFs "data/root-cache";
  fileSystems."/mnt/root/.gnupg" = zfsFs "data/root-gnupg";
  fileSystems."/mnt/root/.persistent" = zfsFs "data/root-files";
  fileSystems."/mnt/root/.ssh" = zfsFs "data/root-ssh";

  # Pedro's home
  fileSystems."/mnt/home/pedrohlc/.cache" = zfsFs "data/my-cache";
  fileSystems."/mnt/home/pedrohlc/.gnupg" = zfsFs "data/my-gnupg";
  fileSystems."/mnt/home/pedrohlc/.local/share/containers" = zfsFs "data/my-containers";
  fileSystems."/mnt/home/pedrohlc/.local/share/Trash" = zfsFs "data/my-trash";
  fileSystems."/mnt/home/pedrohlc/.persistent" = zfsFs "data/my-files";
  fileSystems."/mnt/home/pedrohlc/.ssh" = zfsFs "data/my-ssh";
  fileSystems."/mnt/home/pedrohlc/Downloads" = zfsFs "data/btdownloads";
  fileSystems."/mnt/home/pedrohlc/Projects" = zfsFs "data/my-projects";

  # Pedro's apps
  fileSystems."/mnt/home/pedrohlc/.aws" = zfsFs "apps/aws";
  fileSystems."/mnt/home/pedrohlc/.config/btop" = zfsFs "apps/btop";
  fileSystems."/mnt/home/pedrohlc/.config/discord" = zfsFs "apps/discord";
  fileSystems."/mnt/home/pedrohlc/.config/Element" = zfsFs "apps/element";
  fileSystems."/mnt/home/pedrohlc/.config/Keybase" = zfsFs "apps/keybase-gui";
  fileSystems."/mnt/home/pedrohlc/.config/keybase" = zfsFs "apps/keybase-core";
  fileSystems."/mnt/home/pedrohlc/.config/nvim" = zfsFs "apps/nvim";
  fileSystems."/mnt/home/pedrohlc/.config/obs-studio" = zfsFs "apps/obs-studio";
  fileSystems."/mnt/home/pedrohlc/.config/qBittorrent" = zfsFs "apps/qbittorrent";
  fileSystems."/mnt/home/pedrohlc/.config/spotify" = zfsFs "apps/spotify";
  fileSystems."/mnt/home/pedrohlc/.config/sublime-text" = zfsFs "apps/subl";
  fileSystems."/mnt/home/pedrohlc/.config/TabNine" = zfsFs "apps/tabnine";
  fileSystems."/mnt/home/pedrohlc/.kube" = zfsFs "apps/kube";
  fileSystems."/mnt/home/pedrohlc/.local/share/DBeaverData" = zfsFs "apps/dbeaver";
  fileSystems."/mnt/home/pedrohlc/.local/share/fish" = zfsFs "apps/fish";
  fileSystems."/mnt/home/pedrohlc/.local/share/keybase" = zfsFs "apps/keybase-data";
  fileSystems."/mnt/home/pedrohlc/.local/share/Steam" = zfsFs "apps/steam";
  fileSystems."/mnt/home/pedrohlc/.local/share/TelegramDesktop" = zfsFs "apps/tdesktop";
  fileSystems."/mnt/home/pedrohlc/.local/share/Terraria" = zfsFs "apps/terraria-saves";
  fileSystems."/mnt/home/pedrohlc/.zoom" = zfsFs "apps/zoom";

  # Pedro's games
  fileSystems."/mnt/home/pedrohlc/.local/share/Steam/steamapps/common" = zfsFs "games/steam";
  fileSystems."/mnt/home/pedrohlc/Games" = zfsFs "games/home";

  # Guests' homes
  fileSystems."/mnt/home/melinapn" = zfsFs "guests/melinapn";

  # ...

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/C4D7-B910";
      fsType = "vfat";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
