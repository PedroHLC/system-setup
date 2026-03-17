# Single source of thruth.
let
  addVPNClient = leaf: vpn: machine: machine // {
    vpn = (machine.vpn or { }) // {
      addr = "${machine.hostname}.${vpn.tld}";
      v4 = "${vpn.prefix.v4}.${leaf}";
      v6 = "${vpn.prefix.v6}:${leaf}";
    };
  };
in
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
    zeta = {
      addr = "zeta.${vpn.tld}";
      inherit (machines.lab.vpn) v4 v6;
    };
  };

  machines = {
    lab = addVPNClient "1" vpn {
      hostname = "vps-lab";
      vpn = {
        adguardAdminPort = 3000;
        atuinPort = 8888;
      };
      loopback = {
        adguardPort = 3334;
        bskyPort = 3777;
      };
    };
    desktop = addVPNClient "2" vpn {
      hostname = "desktop";
      vpn = {
        llamaCppPort = 11435;
        nextjsOllamaPort = 3000;
        ollamaPort = 11434;
      };
      lans = { };
    };
    laptop = addVPNClient "3" vpn {
      hostname = "laptop";
      lans = { };
    };
    beacon = addVPNClient "5" vpn {
      hostname = "beacon";
      lans = { };
    };
    foreign = addVPNClient "8" vpn {
      hostname = "foreign";
      lans = { };
    };
  };

  web = {
    lab = {
      addr = "lab.${contact.domain}";
      v4 = "144.22.182.122";
      v6 = "2603:c021:c001:4e00:ebff:9275:c660:f6e1";
    };
    zeta = rec {
      addr = "zeta.${contact.domain}";
      inherit (web.lab) v4 v6;
    };
    bsky.addr = "bsky.chaotic.cx";
    dev.addr = "ubiquelambda.dev";
    desktop.addr = "desk-pedrohlc.duckdns.org";
  };

  contact = {
    domain = "pedrohlc.com";
    email = "root@${contact.domain}";
    namespace = "com.pedrohlc";
    nickname = "PedroHLC";
  };

  privateBucket = path: "https://lab.pedrohlc.com/bucket/${path}";
}
