# ZFS-based impermanence but instead of rolling back on every start, roll back on safe shutdown/halt/reboot
{ config, lib, pkgs, ... }:

let
  cfgZfs = config.boot.zfs;
in
{
  systemd.shutdownRamfs.contents."/etc/systemd/system-shutdown/zpool".source =
    lib.mkForce
      (pkgs.writeShellScript "zpool-sync-shutdown" ''
        ${cfgZfs.package}/bin/zfs rollback -r zroot/ROOT/empty@start
        exec ${cfgZfs.package}/bin/zpool sync
      '');
  systemd.shutdownRamfs.storePaths = [ "${cfgZfs.package}/bin/zfs" ];
}
