utils: with utils;

let
  clients =
    builtins.mapAttrs
      (position: hostname: {
        inherit hostname;
        inherit position;
        activate_on_startup = true;
        ips = mapAttrsToList (_: { v4, ... }: v4) machines.${hostname}.lans;
      })
      kvm;

  config = {
    clients = builtins.attrValues clients;

    port = 4242;

    "authorized_fingerprints" = {
      "b7:5e:5d:a3:3e:20:9c:e8:a8:dc:fa:6c:c5:3c:92:a5:a3:4a:35:ae:2e:aa:8a:43:29:d4:da:be:23:34:ec:63" = "desktop";
      "b5:67:20:e3:71:56:11:e3:0e:80:ff:3f:19:5c:da:12:83:4c:62:5f:7b:f9:24:1d:1b:db:29:ea:22:69:cd:28" = "foreign";
      "8c:bd:ff:d3:d4:45:68:7e:f2:9a:dd:5b:7b:e6:39:e2:75:59:f4:b9:a5:44:e6:28:17:e1:a3:da:3d:19:ed:50" = "laptop";
    };
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
      ExecStart = "${pkgs.lan-mouse_git}/bin/lan-mouse -c ${configFile} daemon";
      Slice = "session.slice";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  launchd.agents.my-kvm = mkIf (isMacOS) {
    enable = true;
    config = {
      Label = "${contact.namespace}.my-kvm";
      ProcessType = "Background";
      ProgramArguments = [ "${pkgs.lan-mouse_git}/bin/lan-mouse" "-c" (toString configFile) "daemon" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
