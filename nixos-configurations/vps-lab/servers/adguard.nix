{ lib, ssot, knownClients, config, ... }: with ssot;
{
  systemd.services.adguardhome.serviceConfig = {
    User = "adguard";
    Group = "adguard";
    DynamicUser = lib.mkForce false;
    Nice = -9;
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
          ecosia = false;
          google = false;
          pixabay = false;
          yandex = false;
          youtube = false;
        };

        archive = {
          enabled = true;
          interval = "360h";
        };

        badGuys =
          if builtins.length knownClients.badBotsCIDRs > 0 then
            [{ name = "Bad"; ids = knownClients.badBotsCIDRs; tags = [ "user_child" ]; uid = "bad"; }]
          else [ ];

        normalizeClient = { name, ids, tags, uid }: {
          # Sadly, I didn't find which of this is required which is optional
          inherit uid safe_search;
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
          ignore_querylog = uid != "bad";
          ignore_statistics = false;
        };

        vpnRule =
          _hostname: { vpn, ... }:
          "||${vpn.addr}^$dnsrewrite=${vpn.v4},client='VPS|VPN";

        internal_rules = [
          "||zeta.pedrohlc.com^$dnsrewrite=127.0.0.1,client='VPS'"
          "||zeta.pedrohlc.com^$dnsrewrite=10.100.0.1,client='VPN'"
        ] ++ (lib.attrsets.mapAttrsToList vpnRule machines);

        refused_domains = map (pattern: "${pattern}$important,dnsrewrite=REFUSED;;") (import ../../../common/refused-domains.nix);
      in
      {
        host = "0.0.0.0";
        port = machines.lab.vpn.adguardAdminPort;
        users = [{
          name = "admin";
          password = "$2y$05$KCSHbkp.59SFVvKg9fHn..CwpXPfZ9p/Azfr/.YB64fNHthHdHTZu"; # admin
        }];
        querylog = archive;
        statistics = archive;
        dns = {
          bind_hosts = [ "0.0.0.0" ];
          upstream_dns = [
            "https://qx1jz8jm5c.cloudflare-gateway.com/dns-query"
            # inmet.gov.br is broken in CF
            "[/gov.br/]tls://dns.google.com"
            # ubisoft cross-play save syncthing is broken in CF
            "[/ubisoft-uplay-savegames.s3.amazonaws.com/]tls://dns.google.com"
            "[/ubi.com/]tls://dns.google.com"
          ];
          upstream_dns_file = "";
          bootstrap_dns = [
            "172.64.36.1"
            "172.64.36.2"
            "2a06:98c1:54::1:ce11"
          ];
          fallback_dns = [
            "tls://dns.google.com"
          ];
          trusted_proxies = [
            "127.0.0.1"
          ];
          cache_enabled = true;
          cache_ttl_max = 43200;
          ratelimit = 300;
          # ratelimit_whitelist = knownClients.goodGuysCIDRs;
          disallowed_clients = knownClients.badBotsCIDRs;
          # In case of fire, break the glass
          # allowed_clients = knownClients.goodGuysCIDRs;
        };
        filtering = {
          filters_update_interval = 1;
          inherit safe_search;
        };
        http = {
          insecure_enabled = true;
        };
        tls = {
          enabled = true;
          server_name = web.zeta.addr;
          force_https = false;
          port_https = machines.lab.loopback.adguardPort;
          port_dns_over_tls = 853;
          port_dns_over_quic = 853;
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
        user_rules = internal_rules ++ [
          # GloboPlay breaks otherwise
          "@@||pubads.g.doubleclick.net^$important"
        ] ++ refused_domains;
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
        # For bumping, read the "Configuration changes" sections of
        # https://github.com/AdguardTeam/AdGuardHome/blob/master/CHANGELOG.md
        schema_version = 34;
      };
  };

  assertions = [
    {
      assertion = config.services.adguardhome.package.passthru.schema_version == config.services.adguardhome.settings.schema_version;
      message = "AdguardHome settings needs a schema_version bump";
    }
  ];
}
