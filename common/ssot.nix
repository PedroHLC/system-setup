# Single source of thruth.
let
  addVPNClient = leaf: vpn: machine: machine // {
    vpn = (machine.vpn or { }) // {
      inherit leaf;
      addr = "${machine.hostname}.${vpn.tld}";
      v4 = "${vpn.prefix.v4}.${leaf}";
      v6 = "${vpn.prefix.v6}:${leaf}";
    };
  };

  homeAddr = leaf: "192.168.98.${leaf}";
in
rec {
  vpn = {
    tld = "vpn.internal";
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
        niks3Port = 5751;
      };
      loopback = {
        adguardPort = 3334;
        bskyPort = 3777;
      };
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDMpd+pMBDgignXPtc202e2ESjDORnzd85jtljuPPfy5PEiRRdWPIYRSETx5bihD74tyH7u27CeAJgt5tl9ig7z4dHBIs+6kn7A6SkFannt7nkQn5CGV44TzsZ4HfZpiH3H7PLuWqDhcceV8A3+P387k4uJwqqN39hH56GgspCcfMAMcg4TZxQRrkp5q32mckSqB9YfNCzUbdafIQKdHuZKA2lnU6lLO+BPXOU/W3u7TsmaCSTI2g4/b80o3eHeApNVYGSHtWSDrnl+smdk24lsJdwGPCixS+x/nqiuLuEM+FWTCb7soovZOlyzHtqTXNNjOA0pg7uEtzNy9qKykE5mznuMNjkVFrfHREOrbyihlcKV87QiIlGJu/kBpF7yY8hL7jR1knyTHD8bluwczKPiE9f9yehgQtW0AjSyEvs1MUyASyNBo+ImAf47SvFqF2E6JEWNAoy0LgYjwjWt1gaP+9dCXVe7YZO4r5pcdLmRUN6Pcb2aiU4+IGVh9jgV5hk= pedrohlc"
      ];
      wgKey = "kjVAAeIGsN0r3StYDQ2vnYg6MbclMrPALdm07qZtRCE=";
    };
    desktop = addVPNClient "2" vpn {
      hostname = "desktop";
      vpn = {
        llamaCppPort = 11435;
        nextjsOllamaPort = 3000;
        ollamaPort = 11434;
      };
      lans = {
        home-wired.v4 = homeAddr "26";
        home-wireless.v4 = homeAddr "21";
      };
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+XO1v27sZQO2yV8q2AfYS/I/l9pHK33a4IjjrNDhV+YBlLbR2iB+L5iNu7x8tKDXYscynxJPHB3vWwerZXOh35SXdh5TE9Lez02Ck466fJnTjNxX63FvppXmMx8HaVYzymojDi+xTXMO4DxNFFrJTUIagWs8WNxEbYdGAaIKRQHB0ZWMSsyaY2XkR9RkV3I9QwKNrTnkC5h8bVn63LvTuORlTvY/Iu202M2toxOKWDQ5qdSrLfNaPl7kxWUVTCpyZ8Hza75sH3SB3/m8Queeq+E48nqjL7s9ZyO1TGf6ojaf2EGfx6H8jFwycXUD2QNLvsZcWmamyLPNbHY63jjOb pedrohlc"
      ];
      wgKey = "cU6dpSqyloVRf6Jjb84TygJO94NOCy+LnMYv6/QAbBs=";
    };
    xbox = addVPNClient "3" vpn {
      hostname = "xbox";
      lans = {
        home-wired.v4 = homeAddr "20";
        home-wireless.v4 = homeAddr "19";
      };
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDe+j0odZ7Mk0p8Q9lv0HWFt62ZW6uN4wi+pp7YD8BquU8cKYlh1yk5kQxzwhEpsrIgyiOYU5CxYWkdblh+h/oLBk7seCzYF+ZZnhR5AJdbUvz8FNPbDqd81tphjntRphNArYVgdpIz0pwvYz9yvDwNXaaPfJuLTIecmIM1PaVnQOTKR6zNhwWad9bXWr4NdS2LN5rl8Yg083BKu36kcdnj8bQi7viNhbpHrwYhDUiMuysUdAd/atNJGwyFehmRckhC/Jv65eJtwR/asXTsEB9KaRAqnuThAR9bGwlMdHP/zZOhB3Bb/M+HTafOlVvBv30iJXg426EUpoMg+X0C0ZOM+wddSDRTmf2z6m/tOxguG0DNwfug1lWjZUlLeevkauBywKo1TlqQEZ9BDFgI/J34YGELJV6hUYe+rQfzcTZwQ9nLx2bcZA877Sf7sAu4ajw+p2Vcz4gypwpdT6vNfDt15w9HKJM/PCAl9Y2OxXOqogrwL1zG9P7tX5adiXp3QW8= pedrohlc"
      ];
      wgKey = "sS6SMVRPPvTGdjVBUScWkYqT8jjT8PIWy0kzMklwITM=";
    };
    beacon = addVPNClient "5" vpn {
      hostname = "beacon";
      lans = { };
      sshKeys = [ ];
      wgKey = "Hsw40VXOzD202Yf/FIoGRd+XdYJjdorPaR7imPy502c=";
    };
    foreign = addVPNClient "8" vpn {
      hostname = "foreign";
      lans = {
        home-wired.v4 = homeAddr "17";
        home-wireless.v4 = homeAddr "23";
      };
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDyrnJw0jEN3OnAHPzMW1eUwNRk03Ba0bU1sLpRh51f+4M1LwLAraQtkg1bKe01cQGWWvNe1NUW0jGFywuvV2jwxcXb5bWSun9FpXfd0B9EMC/+uOCMBlEKflSkbzIGnLNbxWsVgAzzas+RbgyiFIlZ58qpUlhw2Iqp6eUGdH2ZtEm6WwU3PYB21UmEvthiDwfHImiWllpevfCmARMMndZy6/A6ygUrUQ4CBinya5K9SgxSDU20wo8ae4pQERtFIpYoW4HZ3iug/k+RW00Z9ofNN5YAFQYl+kS3jFQVH7Yz2PBbjbhF0qrKWwxg7pSn5gu+YRbZpZhZcqPzkuoZuTTq3/agNcH7nSOGtYFU9Mqx6BU/hRneUWUyLBO2qduHXBHATGvColuO9rMdu6EeVFpeSmVFXnTHkwisaBomQLwQn81aWKsWBPPJ9IbZur4t8SVBWxRunpz05cmgW9xCirzQbF68Uxw6qxG787CDF0aS8r0f/tj5o1Ef2DJhr4w+QV8= pedrohlc"
      ];
      wgKey = "UyVKOBmKQJYeHXQmde6QW+g51K3/qH9hl3lInLCKJhI=";
    };
    telefono = addVPNClient "6" vpn {
      hostname = "telefono";
      lans = { };
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/vOidQLdDQ+vCet6trM5RRZJ6xujf4YJOve4vAdzBCUk30JQ3g3Kbkkdq3AWmvwRpUEkMxMiIGweiFXphvfIJvyHdSXaFoury8Va1n6I5bUS7ntaQI5R2SKBh2WHW1q/tzP5W7UxS4DwYg3kEXZp0V7sqTbw+4t8ctcS51Wam6LuUidqikukYQwKoz9DI9q0B3+U6qTl21jXwpZtqpvcTeC3ElqrkhgN4h4hNgWyjHGmfiB9NpGwPhwyfreRRiyVPXgGU9M9vI7D95ga+6eDS04aQph/MrEWgAh8jDvPzJW4PIQumhTtJdw/8v+vPqPM6+aAlwDoEKnZg1INsBb4R pedrohlc"
      ];
      wgKey = "PIRZl+62B+VvfCy33fhWKBjmmevtmB01qHYzu/W9LX8=";
    };
    astrophone = addVPNClient "9" vpn {
      hostname = "astrophone";
      lans = { };
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGZnStto8hBFlifmfssDdkz0MFEQe9txsX1A/xQNLmQy pedrohc"
      ];
      wgKey = "wR+ygfXJoy9LBzBh0EZmm4Oqb74Y6RtWxBU+TKEWCC8=";
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
    niks3.addr = "nyx-niks3.chaotic.cx";
    dev.addr = "ubiquelambda.dev";
    desktop.addr = "desk-pedrohlc.duckdns.org";
  };

  contact = {
    domain = "pedrohlc.com";
    email = "root@${contact.domain}";
    namespace = "com.pedrohlc";
    nickname = "PedroHLC";
  };

  keyring.ssh =
    builtins.concatMap ({ hostname, sshKeys, ... }: builtins.map (key: "${key}@${hostname}") sshKeys) (builtins.attrValues machines);

  privateBucket = path: "https://lab.pedrohlc.com/bucket/${path}";
}
