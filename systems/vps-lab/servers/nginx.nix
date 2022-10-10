{ lib, ... }:
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "lab.pedrohlc.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/".root = ../../../shared/assets/http-root/lab;
      };
      "zeta.pedrohlc.com" = {
        forceSSL = true;
        useACMEHost = "lab.pedrohlc.com";
        locations = {
          "/".root = ../../../shared/assets/http-root/zeta;
          "/dns-query".proxyPass = "https://127.0.0.1:3334/dns-query";
        };
      };
    };
    appendHttpConfig = ''
      aio threads;
    '';
  };
}
