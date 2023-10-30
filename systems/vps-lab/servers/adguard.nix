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
    settings =
      let
        safe_search = {
          enabled = false;
          bing = false;
          duckduckgo = false;
          google = false;
          pixabay = false;
          yandex = false;
          youtube = false;
        };

        goodGuys = [
          { name = "VPN"; ids = [ vpn.subnet.v4 vpn.subnet.v6 ]; tags = [ "user_admin" ]; }
          { name = "VPS"; ids = [ web.lab.v4 web.lab.v6 ]; tags = [ "user_admin" ]; }
          { name = "Velonic"; ids = [ "168.227.216.0/22" ]; tags = [ "user_admin" ]; }
          { name = "AmericaNet"; ids = [ "186.236.110.0/23" "186.236.122.0/23" ]; tags = [ "user_regular" ]; }
          { name = "VivoWap"; ids = [ "177.67.24.0/21" "2804:33b0::/32" "189.113.128.0/20" ]; tags = [ "user_regular" ]; }
          { name = "Nextel"; ids = [ "191.39.128.0/17" ]; tags = [ "user_regular" ]; }
          { name = "THS"; ids = [ "177.223.240.0/21" ]; tags = [ "user_regular" ]; }
        ];
        badGuys = [{ name = "Bad"; ids = lib.trivial.importJSON ../../../shared/assets/bad-bots.json; tags = [ "user_child" ]; }];

        normalizeClient = { name, ids, tags }: {
          # Sadly, I didn't find which of this is required which is optional
          inherit safe_search;
          blocked_services = {
            schedule.time_zone = "Local";
            ids = [ ];
          };
          inherit name ids tags;
          upstreams = [ ];
          use_global_settings = true;
          filtering_enabled = false;
          parental_enabled = false;
          safebrowsing_enabled = false;
          use_global_blocked_services = true;
          ignore_querylog = false;
          ignore_statistics = false;
        };
      in
      {
        bind_host = "0.0.0.0";
        bind_port = 3000;
        users = [{
          name = "admin";
          password = "$2y$05$KCSHbkp.59SFVvKg9fHn..CwpXPfZ9p/Azfr/.YB64fNHthHdHTZu"; # admin
        }];
        querylog.interval = "2160h";
        statistics.interval = "2160h";
        dns = {
          bind_hosts = [ "0.0.0.0" ];
          upstream_dns = [
            "h3://qx1jz8jm5c.cloudflare-gateway.com/dns-query"
            "[/gov.br/]tls://dns.google.com" # inmet.gov.br is broken in CF
          ];
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
          inherit safe_search;
          allowed_clients = builtins.concatLists (map ({ ids, ... }: ids) goodGuys);
          disallowed_clients = builtins.concatLists (map ({ ids, ... }: ids) badGuys);
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
          # In case of fire, break the glass
          "# ||*^$ctag=user_child,dnsrewrite=REFUSED;;"
          "# ||*^$ctag=~user_admin|~user_regular,dnsrewrite=REFUSED;;"
        ];
        clients = {
          runtime_sources = {
            whois = true;
            arp = true;
            rdns = true;
            dhcp = true;
            hosts = true;
          };
          persistent = map normalizeClient (goodGuys ++ badGuys);
        };
        schema_version = 24;
      };
  };
}
