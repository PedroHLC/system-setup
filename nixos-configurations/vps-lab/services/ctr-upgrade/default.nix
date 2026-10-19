{ config, pkgs, ... }:

{
  systemd.services.onlinectr-upgrade = {
    description = "Auto-upgrade OnlineCTR";
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/etc/nixos";
    };
    path = with pkgs; [ git util-linux config.nix.package nixos-rebuild-ng ];
    script = ''
      runuser -u pedrohlc -- nix flake update onlinectr
      exec nixos-rebuild switch
    '';
  };

  systemd.timers.onlinectr-upgrade = {
    description = "Timer running onlinectr-upgrade every 10 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/10";
      Persistent = true;
    };
  };
}
