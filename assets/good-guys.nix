ssot: with ssot;

[
  { name = "VPN"; ids = [ vpn.subnet.v4 vpn.subnet.v6 ]; tags = [ "user_admin" ]; }
  { name = "VPS"; ids = [ web.lab.v4 web.lab.v6 "127.0.0.1/8" ]; tags = [ "user_admin" ]; }
  { name = "CLOUDFLAREWARP"; ids = [ "2a09:bac0::/29" "104.16.0.0/12" ]; tags = [ "user_regular" ]; }
  { name = "AmericaNet"; ids = [ "186.236.110.0/23" "186.236.122.0/23" "186.236.96.0/19" "187.121.192.0/19" ]; tags = [ "user_regular" ]; }
  {
    name = "Viajantes";
    ids = [
      "160.20.84.0/22"
      "168.121.96.0/22"
      "168.197.226.0/23"
      "177.20.177.0/24"
      "186.193.128.0/20"
      "187.16.8.0/24"
      "187.87.112.0/20"
      "187.95.80.0/20"
      "189.127.192.0/20"
      "191.241.160.0/21"
      "191.5.128.0/20"
      "191.54.0.0/15"
      "200.12.0.0/20"
      "200.160.192.0/20"
      "201.130.20.0/22"
      "200.24.118.0/23"
      "201.54.224.0/20"
      "2804:868::/32"
    ];
    tags = [ "user_regular" ];
  }
  { name = "Descalnet"; ids = [ "132.255.216.0/22" "45.191.128.0/22" ]; tags = [ "user_regular" ]; }
  { name = "Real Internet"; ids = [ "177.8.64.0/22" ]; tags = [ "user_regular" ]; }
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
  { name = "NicNet"; ids = [ "45.4.32.0/22" "38.41.196.0/22" "45.225.168.0/22" "2804:39b0::/32" "2804:4694::/32" ]; tags = [ "user_regular" ]; }
  { name = "Proxer"; ids = [ "45.231.152.0/22" "200.152.27.0/24" ]; tags = [ "user_regular" ]; }
  { name = "THS"; ids = [ "177.223.240.0/20" "186.209.0.0/20" "2804:174::/32" ]; tags = [ "user_regular" ]; }
  { name = "Desktop"; ids = [ "186.249.128.0/19" ]; tags = [ "user_regular" ]; }
  { name = "Velonic"; ids = [ "168.227.216.0/22" "45.167.180.0/22" ]; tags = [ "user_regular" ]; }
  {
    name = "Vivo";
    ids = [
      "152.240.0.0/12"
      "177.102.0.0/15"
      "177.138.0.0/15"
      "177.188.0.0/15"
      "177.212.0.0/14"
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
      "189.108.0.0/15"
      "189.46.0.0/15"
      "189.78.0.0/15"
      "189.96.0.0/15"
      "189.98.0.0/15"
      "191.200.0.0/14"
      "191.254.0.0/15"
      "200.148.0.0/17"
      "200.153.128.0/17"
      "200.161.0.0/16"
      "200.176.3.0/24"
      "200.207.0.0/16"
      "201.13.0.0/16"
      "201.27.0.0/16"
      "201.42.0.0/15"
      "201.95.0.0/16"
      "2804:18::/32"
      "2804:431:c000::/37"
      "2804:431:d000::/37"
      "2804:7efc::/32"
    ];
    tags = [ "user_regular" ];
  }
]
