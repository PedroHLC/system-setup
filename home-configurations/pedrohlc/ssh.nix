utils: with utils;

let
  identityFile = "~/.ssh/pedrohlc_id";

  # This complex block is responsible for adding "Matches *" that search for all my LAN
  # addresses before fallingback to the VPN address
  addMyLocalDevices = base:
    with ullib.attrset; foldl
      (machine: details: accu:
        let
          hostname = details.hostname or machine;

          matchIP = v4: "Match host ${hostname} exec \"nc -w 1 -z ${v4} %p\"";

          lanMatches =
            foldl'
              (network: { v4, ... }: lanAccu:
                union lanAccu
                  (singleton (matchIP v4) (dag.entryBetween [ "Match host ${hostname}" ] (attrNames lanAccu) {
                    HostName = v4;
                  }))
              )
              (details.lans or { })
              { };
        in
        accu
        // lanMatches
        // (with details.vpn; {
          "Match host ${hostname}" = dag.entryBefore [ "${hostname}" ] {
            HostName = v4;
          };
          "${hostname}" = dag.entryBefore [ "${hostname}.vpn" ] { IdentityFile = identityFile; };
          "${hostname}.vpn" = dag.entryAnywhere {
            IdentityFile = identityFile;
            HostName = v4;
          };
        }))
      base
      machines;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings =
      addMyLocalDevices {
        # VPN
        "vps-lab.vpn" = {
          IdentityFile = identityFile;
          HostName = machines.lab.vpn.v4;
        };
        # VCS
        "github.com" = {
          Host = "github.com gist.github.com";
          IdentityFile = identityFile;
          User = "git";
        };
        "github.com-temeraire" = {
          Host = "github.com-temeraire gist.github.com-temeraire";
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_temeraire";
        };
        "gitlab.com" = {
          IdentityFile = identityFile;
          User = "git";
        };
        "bitbucket.com" = {
          IdentityFile = identityFile;
          User = "git";
        };
        "aur.archlinux.org" = {
          IdentityFile = "~/.ssh/pedrohlc_common";
          User = "aur";
        };
        # UFSCar
        "git.ufscar.br" = {
          IdentityFile = identityFile;
        };
        "openhpc.ufscar.br" = {
          IdentityFile = identityFile;
          User = "u726578";
        };
        "*.cluster.infra.ufscar.br" = {
          IdentityFile = identityFile;
          User = "u726578";
          ProxyJump = "openhpc.ufscar.br";
        };
        "wifi-instrucoes.ufscar.br" = {
          IdentityFile = identityFile;
          HostName = "200.133.224.99";
          Port = 5522;
          ProxyJump = "openhpc.ufscar.br";
        };
        "labstatus.ufscar.br" = {
          IdentityFile = identityFile;
          HostName = "200.133.224.78";
          Port = 29376;
          ProxyJump = "openhpc.ufscar.br";
        };
        "*.instrucoes.ufscar.br" = {
          User = "root";
          HostName = "192.168.115.202";
          ProxyJump = "candc.labinfo.ufscar.br";
        };
        # Chaotic
        "bangl.de" = {
          IdentityFile = identityFile;
          User = "chaotic";
        };
        "github-runner.garudalinux.org" = {
          IdentityFile = identityFile;
          HostName = "157.180.57.51";
          Port = 230;
        };
        "aur.archlinux.org-chaotic" = {
          User = "aur";
          HostName = "aur.archlinux.org";
          IdentityFile = "~/Projects/cx.chaotic/aur-sshkey/id_rsa";
        };
      };
  };

  home.file.".ssh/authorized_keys.hm" = mkIf (!isNixOS) {
    text = concatStringsSep "\n" keyring.ssh;
  };

  home.activation.mergeAudacious = mkIf (!isNixOS) (hm.dag.entryAfter [ "onFilesChange" ] ''
    authorizedKeys="$HOME/.ssh/authorized_keys"
    if [[ ! -e "$authorizedKeys" ]]; then
      $DRY_RUN_CMD touch "$authorizedKeys"
      $DRY_RUN_CMD chmod 600 "$authorizedKeys"
      $DRY_RUN_CMD cat "$authorizedKeys.hm" > "$authorizedKeys"
    fi
  '');
}
