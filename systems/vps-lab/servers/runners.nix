{
  services.github-runners = {
    gpl = {
      enable = true;
      name = "pedrohlc-lab";
      extraLabels = [ "nixos" ];
      url = "https://github.com/GamingPalaceOrg";
      tokenFile = "/var/persistent/secrets/runners/gpl.token";
    };
  };
}
