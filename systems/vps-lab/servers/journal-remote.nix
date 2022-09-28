# Adapted from: https://gitlab.com/distrosync/nixos/-/blob/14138e076ba2eb03105cb5733d723f1e98a3d9d3/modules/journal/journal-remote.nix
{ config, pkgs, ... }:
{
  # https://github.com/systemd/systemd/issues/5242
  systemd.timers.remote-journal-rotation = {
    wantedBy = [ "timers.target" ];
    partOf = [ "remote-journal-rotation.service" ];
    timerConfig.OnCalendar = "weekly";
  };
  systemd.services.remote-journal-rotation = {
    serviceConfig.Type = "oneshot";
    script = ''
      journalctl -D /var/log/journal/remote --vacuum-size=5G
    '';
  };

  # The user
  users.users.systemd-journal-remote = {
    isSystemUser = true;
    group = "systemd-journal";
  };

  # Create a directory for the remote logs, so that they inherit the ACLs of the parent /var/log/journal directory.
  systemd.tmpfiles.rules = [ "d /var/log/journal/remote 755 systemd-journal-remote systemd-journal" ];

  # The service
  systemd.services.systemd-journal-remote = {
    enable = true;
    description = "Journal Remote Sink Service";
    documentation = [ "man:systemd-journal-remote(8)" "man:journal-remote.conf(5)" ];
    requires = [ "systemd-journal-remote.socket" ];

    serviceConfig = {
      ExecStart = "/run/current-system/systemd/lib/systemd/systemd-journal-remote --listen-http=-3 --output=/var/log/journal/remote/";
      LockPersonality = "yes";
      LogsDirectory = "journal/remote";
      MemoryDenyWriteExecute = "yes";
      NoNewPrivileges = "yes";
      PrivateDevices = "yes";
      PrivateNetwork = "yes";
      PrivateTmp = "yes";
      ProtectControlGroups = "yes";
      ProtectHome = "yes";
      ProtectHostname = "yes";
      ProtectKernelModules = "yes";
      ProtectKernelTunables = "yes";
      ProtectSystem = "strict";
      RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
      RestrictNamespaces = "yes";
      RestrictRealtime = "yes";
      RestrictSUIDSGID = "yes";
      SystemCallArchitectures = "native";
      User = "systemd-journal-remote";
      Group = "systemd-journal";
      WatchdogSec = "3min";

      LimitNOFILE = "524288";
    };

    wantedBy = [ "multi-user.target" ];
  };

  # The socket-target
  systemd.sockets.systemd-journal-remote = {
    enable = true;
    description = "Journal Remote Sink Socket";
    listenStreams = [ "19532" ];
    wantedBy = [ "sockets.target" ];
  };

}
