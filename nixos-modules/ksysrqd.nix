{ config, pkgs, ... }:

{
  # A module to save me in case everything catches fire
  boot.extraModulePackages = with config.boot.kernelPackages; [
    (callPackage ../packages/ksysrqd.nix { })
  ];

  # The service to start ksysrqd with my secret
  systemd.services.ksysrqd = {
    description = "Load ksysrqd module at boot";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "ksysrqd-ins" ''
        ${pkgs.kmod}/bin/modprobe ksysrqd password=$(cat /var/persistent/secrets/ksysrqd.psw)
      '';
      RemainAfterExit = true;
    };

    wantedBy = [ "multi-user.target" ];
  };

}
