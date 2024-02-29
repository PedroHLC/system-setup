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

  lan-mouse = pkgs.callPackage flakes.lan-mouse { };
in
mkIf (kvm != null) {
  home.sessionVariables.EXPORT_THIS_SHIT = configFile;

  systemd.user.services.my-kvm = {
    Unit = {
      Description = "KVM service";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requires = [ "xdg-desktop-portal.service" ];
    };
    Service = {
      ExecStart = "${lan-mouse}/bin/lan-mouse -d -c ${configFile}";
      Slice = "session.slice";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
