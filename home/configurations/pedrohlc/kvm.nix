utils: with utils;

let
  clients =
    builtins.mapAttrs
      (_: hostname: {
        inherit hostname;
        activate_on_startup = true;
        ips = mapAttrsToList (_: { v4, ... }: v4) lan.${hostname};
      })
      kvm;

  config = clients // {
    port = 4242;
  };

  configFile = (pkgs.formats.toml { }).generate "config.toml" config;
in
mkIf (kvm != null) {
  home.sessionVariables.LAN_MOUSE_CONFIG = configFile;

  systemd.user.services.my-kvm = mkIf (pkgs.stdenv.hostPlatform.isLinux) {
    Unit = {
      Description = "KVM service";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requires = [ "xdg-desktop-portal.service" ];
    };
    Service = {
      ExecStart = "${pkgs.lan-mouse_git}/bin/lan-mouse -d -c ${configFile}";
      Slice = "session.slice";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
