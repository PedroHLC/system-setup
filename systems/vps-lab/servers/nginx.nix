{ pkgs, ... }:
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    package = pkgs.nginxQuic;
    virtualHosts = {
      "lab.pedrohlc.com" = {
        forceSSL = true;
        enableACME = true;
        http3 = true;
        locations."/".root = ../../../shared/assets/http-root/lab;
      };
      "zeta.pedrohlc.com" = {
        forceSSL = true;
        useACMEHost = "lab.pedrohlc.com";
        http3 = true;
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
