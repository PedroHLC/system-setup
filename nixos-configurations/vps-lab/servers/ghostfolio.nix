{ flakes, ssot, pkgs, ... }: with ssot;
{
  imports = [
    flakes.moraxyc.nixosModules.ghostfolio
    ../../../nixos-modules/postgres.nix
  ];

  services.ghostfolio = {
    enable = true;
    package = flakes.moraxyc.packages.${pkgs.stdenv.hostPlatform.system}.ghostfolio;
    host = machines.lab.vpn.v4;
    port = machines.lab.vpn.ghostfolioPort;
    rootUrl = "http://${machines.lab.vpn.v4}:${toString machines.lab.vpn.ghostfolioPort}";
    environmentFile = "/var/persistent/secrets/ghostfolio.env";
  };
}
