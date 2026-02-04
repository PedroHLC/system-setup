proxyAddr: { pkgs, ssot, ... }: with ssot;

unitName: port: moduleInput: {
  systemd.sockets."proxy-${unitName}" = {
    wantedBy = [ "sockets.target" ];

    socketConfig = {
      ListenStream = [
        "${machines.desktop.vpn.v4}:${toString port}"
        "[${machines.desktop.vpn.v6}]:${toString port}"
      ];
      NoDelay = true;
    };
  };

  systemd.services."proxy-${unitName}" = {
    requires = [ "${unitName}.service" "proxy-${unitName}.socket" ];
    after = [ "${unitName}.service" "proxy-${unitName}.socket" ];

    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${proxyAddr}:${toString port}";
      PrivateTmp = true;
    };
  };
}
