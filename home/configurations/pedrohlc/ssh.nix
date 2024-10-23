utils: with utils;

let
  identityFile = "~/.ssh/pedrohlc_id";

  # This complex block is responsible for adding "Matches *" that search for all my LAN
  # addresses before fallingback to the VPN address
  addMyLocalDevices = base:
    with myLib.attrset; foldl
      (machine: n: a: foldl'
        (network: { v4, ... }: union
          (singleton "${machine}.${network}" {
            match = ''host ${machine} exec "nc -w 1 -z ${v4} %p"'';
            hostname = v4;
          })
        )
        n
        a
      // (with vpn.${machine}; {
        "match:${addr}" = {
          match = ''host ${machine}'';
          hostname = v4;
        };
        "${machine}" = { inherit identityFile; };
        "${machine}.vpn" = {
          inherit identityFile;
          hostname = v4;
        };
      }))
      base
      lan;
in
{
  programs.ssh = {
    enable = true;
    matchBlocks =
      addMyLocalDevices {
        # VPN
        "vps-lab.vpn" = { inherit identityFile; };
        # VCS
        "github.com" = {
          host = "github.com gist.github.com";
          inherit identityFile;
          user = "git";
        };
        "github.com-temeraire" = {
          host = "github.com-temeraire gist.github.com-temeraire";
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_temeraire";
        };
        "gitlab.com" = {
          inherit identityFile;
          user = "git";
        };
        "bitbucket.com" = {
          inherit identityFile;
          user = "git";
        };
        "aur.archlinux.org" = {
          identityFile = "~/.ssh/pedrohlc_common";
          user = "aur";
        };
        # UFSCar
        "git.ufscar.br" = {
          inherit identityFile;
        };
        "openhpc.ufscar.br" = {
          inherit identityFile;
          user = "u726578";
        };
        "*.cluster.infra.ufscar.br" = {
          inherit identityFile;
          user = "u726578";
          proxyJump = "openhpc.ufscar.br";
        };
        "wifi-instrucoes.ufscar.br" = {
          inherit identityFile;
          hostname = "200.133.224.99";
          port = 5522;
          proxyJump = "openhpc.ufscar.br";
        };
        "labstatus.ufscar.br" = {
          inherit identityFile;
          hostname = "200.133.224.78";
          port = 29376;
          proxyJump = "openhpc.ufscar.br";
        };
        "*.instrucoes.ufscar.br" = {
          user = "root";
          hostname = "192.168.115.202";
          proxyJump = "candc.labinfo.ufscar.br";
        };
        # Chaotic
        "bangl.de" = {
          inherit identityFile;
          user = "chaotic";
        };
        "github-runner.garudalinux.org" = {
          inherit identityFile;
          hostname = "116.202.208.112";
          port = 230;
        };
        "aur.archlinux.org-chaotic" = {
          host = "aur.archlinux.org-chaotic";
          user = "aur";
          hostname = "aur.archlinux.org";
          identityFile = "~/Projects/cx.chaotic/aur-sshkey/id_rsa";
        };
      };
  };
}
