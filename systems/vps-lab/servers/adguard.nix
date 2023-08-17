{ lib, ssot, ... }: with ssot;
{
  systemd.services.adguardhome = {
    serviceConfig.User = "adguard";
    serviceConfig.Group = "adguard";
    serviceConfig.DynamicUser = lib.mkForce false;
  };

  users.users."adguard" = {
    group = "adguard";
    extraGroups = [ "nginx" ];
    home = "/var/lib/AdGuardHome";
    description = "Adguard DNS";
    createHome = false;
    isSystemUser = true;
  };
  users.groups.adguard = { };

  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    # https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#configuration-file
    settings = {
      bind_host = "0.0.0.0";
      bind_port = 3000;
      users = [{
        name = "admin";
        password = "$2y$05$KCSHbkp.59SFVvKg9fHn..CwpXPfZ9p/Azfr/.YB64fNHthHdHTZu"; # admin
      }];
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        statistics_interval = 90;
        upstream_dns = [ "h3://qx1jz8jm5c.cloudflare-gateway.com/dns-query" ];
        upstream_dns_file = "";
        bootstrap_dns = [
          "172.64.36.1"
          "172.64.36.2"
          "2a06:98c1:54::1:ce11"
        ];
        trusted_proxies = [
          "127.0.0.1"
        ];
        filters_update_interval = 1;
        safe_search = {
          enabled = false;
          bing = false;
          duckduckgo = false;
          google = false;
          pixabay = false;
          yandex = false;
          youtube = false;
        };
      };
      tls = {
        enabled = true;
        server_name = web.zeta.addr;
        force_https = false;
        port_https = vpn.lab.adguardPort;
        port_dns_over_tls = 853;
        port_dns_over_quic = 853;
        allow_unencrypted_doh = true;
        certificate_path = "/var/lib/acme/${web.lab.addr}/cert.pem";
        private_key_path = "/var/lib/acme/${web.lab.addr}/key.pem";
      };
      filters = [
        {
          # AdGuard Base filter, Social media filter, Spyware filter, Mobile ads filter, EasyList and EasyPrivacy
          # https://kb.adguard.com/en/general/adguard-ad-filters#adguard-filters
          enabled = true;
          url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
      ];
      user_rules = [
        # GloboPlay breaks otherwise
        "@@||pubads.g.doubleclick.net^$important"
      ];
      schema_version = 20;
    };
  };
}
