utils: with utils;

# My simple and humble bar
mkIf (kvm != null) {
  systemd.user.services.my-kvm = {
    Unit = {
      Description = "KVM service";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requires = [ "xdg-desktop-portal.service" ];
    };
    Service = {
      ExecStart =
        if kvm == "host" then
          "${pkgs.input-leap_git}/bin/input-leaps --config ${../../../shared/assets/input-leap.conf} --use-ei --no-daemon --disable-crypto"
        else if kvm == "guest" then
          "${pkgs.waynergy}/bin/waynergy --backend wlr --host ${lan.laptop.home-wire.v4} --disable-crypto"
        else "Unsupported KVM mode";
      Slice = "session.slice";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
