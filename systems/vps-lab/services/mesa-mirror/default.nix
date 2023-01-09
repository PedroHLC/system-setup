{ pkgs, lib, ... }:
let
  script = pkgs.resholve.writeScript "mesa-mirror.sh"
    {
      inputs = [ pkgs.git pkgs.gnugrep pkgs.coreutils ];
      interpreter = "${pkgs.bash}/bin/bash";
      execer = [
        "cannot:${pkgs.git}/bin/git"
      ];
    }
    (builtins.readFile ./mesa-mirror.sh);
in
{
  systemd.services.mesa-mirror = {
    description = "Mirror FreeDesktop's Mesa";
    serviceConfig = {
      Type = "oneshot";
      User = "pedrohlc";
      Group = "users";
      ExecStart = script;
    };
  };

  systemd.timers.mesa-mirror = {
    description = "Mirror FreeDesktop's Mesa (timer)";
    wantedBy = [ "timers.target" ];
    after = [ "network-online.target" ];
    timerConfig = {
      OnCalendar = [ "*:0/5" ];
      AccuracySec = "5m";
      Unit = "mesa-mirror.service";
    };
  };
}
