# Single source of thruth.
_:

rec {
  vpn = {
    tld = "vpn";
    port = 51820;
    prefix = {
      v4 = "10.100.0";
      v6 = "fda4:4413:3bb1:"; # generated using `subnetcalc fd00:: 48 -uniquelocal`
    };
    mask = {
      v4 = "24";
      v6 = "64";
    };
    subnet = {
      v4 = "${vpn.prefix.v4}.0/${vpn.mask.v4}";
      v6 = "${vpn.prefix.v6}:/${vpn.mask.v6}";
    };
    lab = rec {
      hostname = "vps-lab";
      addr = "${hostname}.${vpn.tld}";
      v4 = "${vpn.prefix.v4}.1";
      v6 = "${vpn.prefix.v6}:1";
      adguardPort = 3334;
      libredditPort = 3380;
    };
    zeta = rec {
      addr = "zeta.${vpn.tld}";
      inherit (vpn.lab) v4 v6;
    };
    libreddit = rec {
      addr = "reddit.${vpn.tld}";
      inherit (vpn.lab) v4 v6;
    };
    desktop = rec {
      hostname = "desktop";
      addr = "${hostname}.${vpn.tld}";
      v4 = "${vpn.prefix.v4}.2";
      v6 = "${vpn.prefix.v6}:2";
    };
    laptop = rec {
      hostname = "laptop";
      addr = "${hostname}.${vpn.tld}";
      v4 = "${vpn.prefix.v4}.3";
      v6 = "${vpn.prefix.v6}:3";
    };
    beacon = rec {
      hostname = "beacon";
      addr = "${hostname}.${vpn.tld}";
      v4 = "${vpn.prefix.v4}.5";
      v6 = "${vpn.prefix.v6}:5";
    };
  };

  web = {
    lab = {
      addr = "lab.${contact.domain}";
      v4 = "144.22.182.122";
      v6 = "2603:c021:c001:4e00:ebff:9275:c660:f6e1";
    };
    dev = {
      addr = "ubiquelambda.dev";
    };
    zeta = {
      addr = "zeta.${contact.domain}";
      inherit (web.lab) v4 v6;
    };
    libreddit = rec {
      addr = "reddit.${contact.domain}";
      inherit (web.lab) v4 v6;
    };
    desktop = {
      addr = "desk-pedrohlc.duckdns.org";
    };
  };

  contact = {
    domain = "pedrohlc.com";
    email = "root@${contact.domain}";
    nickname = "PedroHLC";
  };
}
