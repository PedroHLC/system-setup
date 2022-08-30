{ ... }:
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "lab.pedrohlc.com" = {
        forceSSL = true;
        enableACME = true;
      };
      "zeta.pedrohlc.com" = {
        forceSSL = true;
        useACMEHost = "lab.pedrohlc.com";
        locations."/dns-query" = {
          proxyPass = "https://127.0.0.1:3334/dns-query";
        };
      };
    };
  };
}
