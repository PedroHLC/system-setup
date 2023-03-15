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
    settings = {
      bind_host = "0.0.0.0"; # bind_host
      bind_port = 3000; # bind_port
      #beta_bind_port = 0;
      users = [{
        name = "admin";
        password = "$2y$05$KCSHbkp.59SFVvKg9fHn..CwpXPfZ9p/Azfr/.YB64fNHthHdHTZu"; # admin
      }];
      #auth_attempts = 5;
      #block_auth_min = 15;
      #http_proxy = "";
      #language = "";
      #debug_pprof = false;
      #web_session_ttl = 720;
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        #port = 53;
        statistics_interval = 90;
        #querylog_enabled = true;
        #querylog_file_enabled = true;
        #querylog_interval = "2160h";
        #querylog_size_memory = 1000;
        #anonymize_client_ip = false;
        #protection_enabled = true;
        #blocking_mode = default;
        #blocking_ipv4 = "";
        #blocking_ipv6 = "";
        #blocked_response_ttl = 10;
        #parental_block_host = "family-block.dns.adguard.com";
        #safebrowsing_block_host = "standard-block.dns.adguard.com";
        #ratelimit = 20;
        #ratelimit_whitelist = [ ];
        #refuse_any = true;
        upstream_dns = [ "https://cloudflare-dns.com/dns-query" ];
        upstream_dns_file = "";
        bootstrap_dns = [
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
        #all_servers = false;
        #fastest_addr = false;
        #fastest_timeout = "1s";
        #allowed_clients = [ ];
        #disallowed_clients = [ ];
        #blocked_hosts = [
        #  "version.bind"
        #  "id.server"
        #  "hostname.bind"
        #];
        trusted_proxies = [
          "127.0.0.1"
        ];
        #cache_size = 4194304;
        #cache_ttl_min = 0;
        #cache_ttl_max = 0;
        #cache_optimistic = false;
        #bogus_nxdomain = [ ];
        #aaaa_disabled = false;
        #enable_dnssec = false;
        #edns_client_subnet = false;
        #max_goroutines = 300;
        #ipset = [ ];
        #filtering_enabled = true;
        filters_update_interval = 1;
        #parental_enabled = false;
        #safesearch_enabled = false;
        #safebrowsing_enabled = false;
        #safebrowsing_cache_size = 1048576;
        #safesearch_cache_size = 1048576;
        #parental_cache_size = 1048576;
        #cache_time = 30;
        #rewrites = [ ];
        #blocked_services = [ ];
        #upstream_timeout = "10s";
        #private_networks = [ ];
        #use_private_ptr_resolvers = true;
        #local_ptr_upstreams = [ ];
      };
      tls = {
        enabled = true;
        server_name = web.zeta.addr;
        force_https = false;
        port_https = vpn.lab.adguardPort;
        port_dns_over_tls = 853;
        port_dns_over_quic = 853;
        #port_dnscrypt = 0;
        #dnscrypt_config_file = "";
        allow_unencrypted_doh = true;
        #strict_sni_check = false;
        #certificate_chain = "";
        #private_key = "";
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
      #whitelist_filters = [ ];
      #user_rules = [ ];
      #dhcp = {
      #  enabled = false;
      #  interface_name = "";
      #  local_domain_name = "lan";
      #  dhcpv4 = {
      #    gateway_ip = "";
      #    subnet_mask = "";
      #    range_start = "";
      #    range_end = "";
      #    lease_duration = 86400;
      #    icmp_timeout_msec = 1000;
      #    options = [ ];
      #  };
      #  dhcpv6 = {
      #    range_start = "";
      #    lease_duration = 86400;
      #    ra_slaac_only = false;
      #    ra_allow_slaac = false;
      #  };
      #};
      #clients = {
      #  runtime_sources = {
      #    whois = true;
      #    arp = true;
      #    rdns = true;
      #    dhcp = true;
      #    hosts = true;
      #  };
      #  persistent = [ ];
      #};
      #log_compress = false;
      #log_localtime = false;
      #log_max_backups = 0;
      #log_max_size = 100;
      #log_max_age = 3;
      #log_file = "";
      #verbose = false;
      #os = {
      #  group = "";
      #  user = "";
      #  rlimit_nofile = 0;
      #};
      schema_version = 14;
    };
  };
}
