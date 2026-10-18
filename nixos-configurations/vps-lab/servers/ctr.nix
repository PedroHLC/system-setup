{ flakes, pkgs, ... }:

let
  pkg = pkgs.pkgsCross.armv7l-hf-multiplatform.callPackage "${flakes.onlineCTR}/" { };
in
{
  systemd.services.ctr = {
    enable = true;
    description = "CTR-ModSDK Online Server";
    serviceConfig = {
      ExecStart = "${pkg}/bin/ctr_srv -p 64001";
      Restart = "always";
      RestartSec = "8";

      DynamicUser = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;

      EnvironmentFile = [ "/var/persistent/secrets/octr-server.env.brz" ];
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
