{ pkgs, ssot, ... }: with ssot;
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    package = pkgs.nginxQuic;
    virtualHosts = {
      "${web.dev.addr}" = {
        forceSSL = true;
        useACMEHost = web.lab.addr;
        http3 = true;
        locations."/".return = "302 https://github.com/UbiqueLambda";
      };
      "${web.lab.addr}" = {
        forceSSL = true;
        enableACME = true;
        http3 = true;
        locations."/".root = ../../../assets/http-root/lab;
        locations."/bucket/".root = "/srv/http";
        locations."/ical/".root = "/srv/http";
      };
      "${web.zeta.addr}" = {
        forceSSL = true;
        useACMEHost = web.lab.addr;
        http3 = true;
        locations = {
          "/".root = ../../../assets/http-root/zeta;
          "/dns-query".proxyPass = "https://127.0.0.1:${toString machines.lab.loopback.adguardPort}/dns-query";
        };
      };
      "${web.bsky.addr}" = {
        forceSSL = true;
        enableACME = true;
        http3 = true;
        serverAliases = [ "pedrohlc.${web.bsky.addr}" ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString machines.lab.loopback.bskyPort}/";
          proxyWebsockets = true;
        };
      };
    };
    appendHttpConfig = ''
      aio threads;
    '';
  };
}
