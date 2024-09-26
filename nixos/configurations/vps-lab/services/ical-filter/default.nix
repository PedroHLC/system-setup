{ pkgs, lib, ... }:
let
  script = pkgs.resholve.writeScript "ical-filter.sh"
    {
      inputs = [ pkgs.curl pkgs.gawk pkgs.coreutils ];
      interpreter = "${pkgs.bash}/bin/bash";
      execer = [
        "cannot:${pkgs.curl}/bin/curl"
        "cannot:${pkgs.gawk}/bin/awk"
      ];
    }
    (builtins.readFile ./ical-filter.sh);
in
{
  systemd.services.ical-filter = {
    description = "Filter some iCals";
    serviceConfig = {
      Type = "oneshot";
      User = "pedrohlc";
      Group = "nginx";
      ExecStart = script;
    };
    path = [ pkgs.openssh ]; # needed for git
  };

  systemd.timers.ical-filter = {
    description = "Filter some iCals (timer)";
    wantedBy = [ "timers.target" ];
    after = [ "network-online.target" ];
    timerConfig = {
      OnCalendar = [ "*:0/15" ];
      AccuracySec = "5m";
      Unit = "ical-filter.service";
    };
  };
}
