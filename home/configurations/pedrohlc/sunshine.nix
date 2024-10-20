utils: with utils;

# Broadcast to Living Room's TV
mkIf sunshine {
  systemd.user.services.my-sunshine = {
    Unit = {
      Description = "Sunshine service";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requires = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "/run/wrappers/bin/sunshine";
      Slice = "session.slice";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ ];
  };
}
