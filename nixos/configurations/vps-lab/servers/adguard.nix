{ lib, ssot, knownClients, flakes, ... }@inputs: with ssot;
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
    package = flakes.nixpkgs-old.legacyPackages.aarch64-linux.adguardhome;
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
        };

        badGuys = [{ name = "Bad"; ids = knownClients.badBotsCIDRs; tags = [ "user_child" ]; bad = true; }];

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
        host = "0.0.0.0";
        port = 3000;
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
          ratelimit = 50;
          # ratelimit_whitelist = knownClients.goodGuysCIDRs;
          inherit safe_search;
          # In case of fire, break the glass
          # allowed_clients = knownClients.goodGuysCIDRs;
          disallowed_clients = knownClients.badBotsCIDRs;
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
          "||bind^$important,dnsrewrite=REFUSED;;"
          "||cnnic.cn^$important,dnsrewrite=REFUSED;;"
          "||cyberresilience.io^$important,dnsrewrite=REFUSED;;"
          "||dnsavailable.xyz^$important,dnsrewrite=REFUSED;;"
          "||dnsmeasurement.com^$important,dnsrewrite=REFUSED;;"
          "||dnsresearch.cymru.com^$important,dnsrewrite=REFUSED;;"
          "||drakkarns.com^$important,dnsrewrite=REFUSED;;"
          "||echodns.xyz^$important,dnsrewrite=REFUSED;;"
          "||ictdns.fun^$important,dnsrewrite=REFUSED;;"
          "||ident.me^$important,dnsrewrite=REFUSED;;"
          "||ki3ednstest.com^$important,dnsrewrite=REFUSED;;"
          "||kohls.com^$important,dnsrewrite=REFUSED;;"
          "||meshtrust.work^$important,dnsrewrite=REFUSED;;"
          "||norahdoe.online^$important,dnsrewrite=REFUSED;;"
          "||odns.m.dnsscan.top^$important,dnsrewrite=REFUSED;;"
          "||open-resolver-scan.research.icann.org^$important,dnsrewrite=REFUSED;;"
          "||openresolver.dnslab.cn^$important,dnsrewrite=REFUSED;;"
          "||research.a10protects.com^$important,dnsrewrite=REFUSED;;"
          "||research.nawrocki.berlin^$important,dnsrewrite=REFUSED;;"
          "||research.openresolve.rs^$important,dnsrewrite=REFUSED;;"
          "||root-servers.net^$important,dnsrewrite=REFUSED;;"
          "||secshow.net^$important,dnsrewrite=REFUSED;;"
          "||ta6.ch^$important,dnsrewrite=REFUSED;;"
          "||whitechun.lol^$important,dnsrewrite=REFUSED;;"
          "||yndx.net^$important,dnsrewrite=REFUSED;;"
        ];
        clients = {
          runtime_sources = {
            whois = true;
            arp = true;
            rdns = true;
            dhcp = true;
            hosts = true;
          };
          persistent = map normalizeClient (knownClients.goodGuys ++ badGuys);
        };
        log = {
          file = "/var/log/AdGuardHome/full.log";
          compress = false;
          local_time = false;
          max_backups = 1;
          max_size = 50;
          max_age = 30;
          verbose = true;
        };
        schema_version = 24;
      };
  };
}
