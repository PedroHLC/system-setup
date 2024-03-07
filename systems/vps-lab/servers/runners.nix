{
  services.github-runners = {
    gpl = {
      enable = false; # BROKEN RIGHT NOW
      name = "pedrohlc-lab";
      extraLabels = [ "nixos" ];
      url = "https://github.com/GamingPalaceOrg";
      tokenFile = "/var/persistent/secrets/runners/gpl.token";
    };
  };
}
