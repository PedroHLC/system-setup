# Adapted from: https://gitlab.com/distrosync/nixos/-/blob/14138e076ba2eb03105cb5733d723f1e98a3d9d3/modules/journal/journal-upload.nix
{ config, pkgs, ssot, ... }: with ssot;
{
  users.users.systemd-journal-upload = {
    isSystemUser = true;
    group = "systemd-journal";
  };

  systemd.services.systemd-journal-upload = {
    enable = true;
    description = "Journal Remote Upload Service";
    documentation = [ "man:systemd-journal-upload(8)" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      DynamicUser = "yes";
      ExecStart = "/run/current-system/systemd/lib/systemd/systemd-journal-upload --save-state -u http://${vpn.lab.addr}:19532";
      LockPersonality = "yes";
      MemoryDenyWriteExecute = "yes";
      PrivateDevices = "yes";
      ProtectControlGroups = "yes";
      ProtectHome = "yes";
      ProtectHostname = "yes";
      ProtectKernelModules = "yes";
      ProtectKernelTunables = "yes";
      Restart = "always";
      RestartSec = "10";
      RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
      RestrictNamespaces = "yes";
      RestrictRealtime = "yes";
      StateDirectory = "systemd/journal-upload";
      SupplementaryGroups = "systemd-journal";
      SystemCallArchitectures = "native";
      User = "systemd-journal-upload";
      WatchdogSec = "3min";

      LimitNOFILE = "524288";
    };

    wantedBy = [ "multi-user.target" ];
  };

}
