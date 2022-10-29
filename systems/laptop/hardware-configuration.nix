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

  # System's filesystem
  fileSystems."/" = zfsFs "ROOT/empty";
  fileSystems."/nix" = zfsFs "ROOT/nix";
  fileSystems."/var/cache" = zfsFs "ROOT/var-cache";
  fileSystems."/var/log" = zfsFs "ROOT/var-log";

  # System's data
  fileSystems."/etc/NetworkManager/system-connections" = zfsFs "data/connections";
  fileSystems."/etc/nixos" = zfsFs "data/setup";
  fileSystems."/etc/ssh" = zfsFs "data/sshd";
  fileSystems."/var/lib/bluetooth" = zfsFs "data/bluetooth";
  fileSystems."/var/lib/containers" = zfsFs "data/containers";
  fileSystems."/var/lib/flatpak" = zfsFs "data/flatpak";
  fileSystems."/var/lib/postgresql" = zfsFs "data/postgres";
  fileSystems."/var/lib/systemd" = zfsFs "data/systemd";
  fileSystems."/var/lib/upower" = zfsFs "data/upower";

  # Root's home
  fileSystems."/root/.cache" = zfsFs "data/root-cache";
  fileSystems."/root/.gnupg" = zfsFs "data/root-gnupg";
  fileSystems."/root/.persistent" = zfsFs "data/root-files";
  fileSystems."/root/.ssh" = zfsFs "data/root-ssh";

  # Pedro's home
  fileSystems."/home/pedrohlc/.cache" = zfsFs "data/my-cache";
  fileSystems."/home/pedrohlc/.gnupg" = zfsFs "data/my-gnupg";
  fileSystems."/home/pedrohlc/.local/share/containers" = zfsFs "data/my-containers";
  fileSystems."/home/pedrohlc/.local/share/Trash" = zfsFs "data/my-trash";
  fileSystems."/home/pedrohlc/.persistent" = zfsFs "data/my-files";
  fileSystems."/home/pedrohlc/.ssh" = zfsFs "data/my-ssh";
  fileSystems."/home/pedrohlc/Downloads" = zfsFs "data/btdownloads";
  fileSystems."/home/pedrohlc/Projects" = zfsFs "data/my-projects";

  # Pedro's apps
  fileSystems."/home/pedrohlc/.aws" = zfsFs "apps/aws";
  fileSystems."/home/pedrohlc/.config/btop" = zfsFs "apps/btop";
  fileSystems."/home/pedrohlc/.config/discord" = zfsFs "apps/discord";
  fileSystems."/home/pedrohlc/.config/Element" = zfsFs "apps/element";
  fileSystems."/home/pedrohlc/.config/Keybase" = zfsFs "apps/keybase-gui";
  fileSystems."/home/pedrohlc/.config/keybase" = zfsFs "apps/keybase-core";
  fileSystems."/home/pedrohlc/.config/nvim" = zfsFs "apps/nvim";
  fileSystems."/home/pedrohlc/.config/obs-studio" = zfsFs "apps/obs-studio";
  fileSystems."/home/pedrohlc/.config/qBittorrent" = zfsFs "apps/qbittorrent";
  fileSystems."/home/pedrohlc/.config/spotify" = zfsFs "apps/spotify";
  fileSystems."/home/pedrohlc/.config/sublime-text" = zfsFs "apps/subl";
  fileSystems."/home/pedrohlc/.config/TabNine" = zfsFs "apps/tabnine";
  fileSystems."/home/pedrohlc/.kube" = zfsFs "apps/kube";
  fileSystems."/home/pedrohlc/.local/share/DBeaverData" = zfsFs "apps/dbeaver";
  fileSystems."/home/pedrohlc/.local/share/fish" = zfsFs "apps/fish";
  fileSystems."/home/pedrohlc/.local/share/keybase" = zfsFs "apps/keybase-data";
  fileSystems."/home/pedrohlc/.local/share/Steam" = zfsFs "apps/steam";
  fileSystems."/home/pedrohlc/.local/share/TelegramDesktop" = zfsFs "apps/tdesktop";
  fileSystems."/home/pedrohlc/.local/share/Terraria" = zfsFs "apps/terraria-saves";
  fileSystems."/home/pedrohlc/.zoom" = zfsFs "apps/zoom";

  # Pedro's games
  fileSystems."/home/pedrohlc/.local/share/Steam/steamapps/common" = zfsFs "games/steam";
  fileSystems."/home/pedrohlc/Games" = zfsFs "games/home";

  # Guests' homes
  fileSystems."/home/melinapn" = zfsFs "guests/melinapn";

  # Legacy
  fileSystems."/mnt" = zfsFs "ROOT/default";
  fileSystems."/mnt/home" = zfsFs "data/home";

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
