{ pkgs, ssot, ... }: with ssot;
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    package = pkgs.nginxQuic;
    virtualHosts = {
      "${web.lab.addr}" = {
        forceSSL = true;
        enableACME = true;
        http3 = true;
        locations."/".root = ../../../shared/assets/http-root/lab;
        locations."/bucket/".root = "/srv/http";
      };
      "${web.zeta.addr}" = {
        forceSSL = true;
        useACMEHost = web.lab.addr;
        http3 = true;
        locations = {
          "/".root = ../../../shared/assets/http-root/zeta;
          "/dns-query".proxyPass = "https://127.0.0.1:${toString vpn.lab.adguardPort}/dns-query";
        };
      };
    };
    appendHttpConfig = ''
      aio threads;
    '';
  };
}
