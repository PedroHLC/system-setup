{ pkgs, lib, ... }:
let
  script = pkgs.resholve.writeScript "gits-mirror.sh"
    {
      inputs = [ pkgs.git pkgs.coreutils ];
      interpreter = "${pkgs.bash}/bin/bash";
      execer = [
        "cannot:${pkgs.git}/bin/git"
      ];
    }
    (builtins.readFile ./gits-mirror.sh);
in
{
  systemd.services.gits-mirror = {
    description = "Mirror many Gits";
    serviceConfig = {
      Type = "oneshot";
      User = "pedrohlc";
      Group = "nginx";
      ExecStart = script;
    };
    path = [ pkgs.openssh ]; # needed for git
  };

  systemd.timers.gits-mirror = {
    description = "Mirror many Gits (timer)";
    wantedBy = [ "timers.target" ];
    after = [ "network-online.target" ];
    timerConfig = {
      OnCalendar = [ "*:0/15" ];
      AccuracySec = "5m";
      Unit = "gits-mirror.service";
    };
  };
}
