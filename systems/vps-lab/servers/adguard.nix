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

        archive = {
          enabled = true;
          interval = "360h";
          #ignored = [ "cisco.com" "apple.com" "atlassian.com" ];
        };

        goodGuys = [
          { name = "VPN"; ids = [ vpn.subnet.v4 vpn.subnet.v6 ]; tags = [ "user_admin" ]; }
          { name = "VPS"; ids = [ web.lab.v4 web.lab.v6 "127.0.0.1/8" ]; tags = [ "user_admin" ]; }
          { name = "CLOUDFLAREWARP"; ids = [ "2a09:bac0::/29" "104.16.0.0/12" ]; tags = [ "user_regular" ]; }
          { name = "AmericaNet"; ids = [ "186.236.110.0/23" "186.236.122.0/23" "186.236.96.0/19" "187.121.192.0/19" ]; tags = [ "user_regular" ]; }
          { name = "Viajantes"; ids = [
            "168.121.96.0/22"
            "168.197.226.0/23"
            "186.193.128.0/20"
            "187.87.112.0/20"
            "187.95.80.0/20"
            "189.127.192.0/20"
            "191.241.160.0/21"
            "200.12.0.0/20"
            "200.160.192.0/20"
            "201.130.20.0/22"
            "201.54.224.0/20"
            "2804:868::/32"
          ]; tags = [ "user_regular" ]; }
          { name = "Descalnet"; ids = [ "132.255.216.0/22" "45.191.128.0/22" ]; tags = [ "user_regular" ]; }
          { name = "Fluke"; ids = [ "177.67.24.0/22" "2804:33b0::/32" "189.113.128.0/20" ]; tags = [ "user_regular" ]; }
          {
            name = "Nextel";
            ids = [
              "177.56.0.0/14"
              "179.224.0.0/15"
              "179.240.0.0/14"
              "187.183.32.0/19"
              "187.24.0.0/14"
              "187.43.0.0/16"
              "187.68.0.0/14"
              "189.120.0.0/16"
              "189.92.0.0/14"
              "191.244.0.0/14"
              "191.38.0.0/15"
              "191.56.0.0/14"
              "200.173.0.0/16"
              "200.182.0.0/16"
              "2804:14c:100::/40"
              "2804:388::/30"
            ];
            tags = [ "user_regular" ];
          }
          { name = "NicNet"; ids = [ "45.4.32.0/22" "38.41.196.0/22" "2804:39b0::/32" ]; tags = [ "user_regular" ]; }
          { name = "Proxer"; ids = [ "45.231.152.0/22" "200.152.27.0/24" ]; tags = [ "user_regular" ]; }
          { name = "THS"; ids = [ "177.223.240.0/20" "186.209.0.0/20" "2804:174::/32" ]; tags = [ "user_regular" ]; }
          { name = "Velonic"; ids = [ "168.227.216.0/22" "45.167.180.0/22" ]; tags = [ "user_regular" ]; }
          {
            name = "Vivo";
            ids = [
              "152.240.0.0/12"
              "177.102.0.0/15"
              "177.138.0.0/15"
              "177.24.0.0/14"
              "177.60.0.0/14"
              "177.68.0.0/16"
              "177.76.0.0/14"
              "179.112.0.0/14"
              "179.224.0.0/14"
              "179.98.0.0/15"
              "187.116.0.0/14"
              "187.56.0.0/15"
              "187.88.0.0/14"
              "189.46.0.0/15"
              "189.96.0.0/15"
              "189.98.0.0/15"
              "200.148.0.0/17"
              "200.153.128.0/17"
              "200.176.3.0/24"
              "200.207.0.0/16"
              "201.13.0.0/16"
              "201.27.0.0/16"
              "2804:18::/32"
              "2804:431:c000::/37"
              "2804:431:d000::/37"
              "2804:7efc::/32"
            ];
            tags = [ "user_regular" ];
          }
        ];
        badGuys = [{ name = "Bad"; ids = lib.trivial.importJSON ../../../shared/assets/bad-bots.json; tags = [ "user_child" ]; bad = true; }];

        goodGuysIds = builtins.concatLists (map ({ ids, ... }: ids) goodGuys);

        normalizeClient = { name, ids, tags, bad ? false }: {
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
          ignore_querylog = !bad;
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
        querylog = archive;
        statistics = archive;
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
          ratelimit = 8;
          ratelimit_whitelist = goodGuysIds;
          inherit safe_search;
          # In case of fire, break the glass
          # allowed_clients = goodGuysIds;
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
          # Blocks most of the amplifications I was having
          "|atlassian.com^$important,dnsrewrite=REFUSED;;"
          "|apple.com^$important,dnsrewrite=REFUSED;;"
          "|cisco.com^$important,dnsrewrite=REFUSED;;"
          # Stop tons of scanning
          "|direct.shodan.io^$important,dnsrewrite=REFUSED;;"
          "|dnsscan.shadowserver.org^$important,dnsrewrite=REFUSED;;"
          "|ip.parrotdns.com^$important,dnsrewrite=REFUSED;;"
          "|jd.com^$important,dnsrewrite=REFUSED;;"
          "|testip.internet-census.org^$important,dnsrewrite=REFUSED;;"
          "|www.stage^$important,dnsrewrite=REFUSED;;"
          "||1u1gpup5i8kbtvctq9peakblhhzk.com^$important,dnsrewrite=REFUSED;;"
          "||anictdns.store^$important,dnsrewrite=REFUSED;;"
          "||asertdnsresearch.com^$important,dnsrewrite=REFUSED;;"
          "||astrill4u.com^$important,dnsrewrite=REFUSED;;"
          "||cyberresilience.io^$important,dnsrewrite=REFUSED;;"
          "||dnsavailable.xyz^$important,dnsrewrite=REFUSED;;"
          "||dnsresearch.cymru.com^$important,dnsrewrite=REFUSED;;"
          "||drakkarns.com^$important,dnsrewrite=REFUSED;;"
          "||echodns.xyz^$important,dnsrewrite=REFUSED;;"
          "||ident.me^$important,dnsrewrite=REFUSED;;"
          "||kohls.com^$important,dnsrewrite=REFUSED;;"
          "||meshtrust.work^$important,dnsrewrite=REFUSED;;"
          "||odns.m.dnsscan.top^$important,dnsrewrite=REFUSED;;"
          "||open-resolver-scan.research.icann.org^$important,dnsrewrite=REFUSED;;"
          "||openresolver.dnslab.cn^$important,dnsrewrite=REFUSED;;"
          "||research.a10protects.com^$important,dnsrewrite=REFUSED;;"
          "||research.openresolve.rs^$important,dnsrewrite=REFUSED;;"
          "||root-servers.net^$important,dnsrewrite=REFUSED;;"
          "||secshow.net^$important,dnsrewrite=REFUSED;;"
          "||ta6.ch^$important,dnsrewrite=REFUSED;;"
          "||whitechun.lol^$important,dnsrewrite=REFUSED;;"
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
