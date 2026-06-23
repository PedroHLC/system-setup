# The top lambda and it super set of parameters.
{ config, lib, pkgs, ssot, ... }: with ssot;

# NixOS-defined options
{
  # Network.
  networking = {
    hostId = "0f8623ae";
    hostName = machines.xbox.hostname;

    # Wireguard Client
    wireguard.interfaces.wg0 = {
      ips = [ "${machines.xbox.vpn.v4}/${vpn.mask.v4}" "${machines.xbox.vpn.v6}/${vpn.mask.v6}" ];
      privateKeyFile = "/var/persistent/secrets/wireguard-keys/private";
    };

    wireguard.interfaces.wg1.privateKeyFile = "/var/persistent/secrets/wgcf-teams/private";
  };

  # Limit resources used by nix-daemon.
  systemd.services.nix-daemon.serviceConfig.AllowedCPUs = "2-15";

  # Melina may also use this machine
  users.users.melinapn = {
    uid = 1002;
    isNormalUser = true;
    extraGroups = [ "users" ];
  };

  # Shadow can't be added to persistent
  users.users."melinapn".hashedPasswordFile = "/var/persistent/secrets/shadow/melinapn";

  # Airplay speaker
  services.shairport-sync.settings = {
     general.interface = "enp2s0";
     pipewire.sink_target = "alsa_output.pci-0000_04_00.6.analog-stereo";
  };

  # Autologin (with Melina).
  services.getty = {
    loginProgram = "${pkgs.bash}/bin/sh";
    loginOptions =
      let
        programScript = pkgs.callPackage ../../packages/login-program.nix {
          loginsPerTTY = {
            "/dev/tty1" = "pedrohlc";
            "/dev/tty2" = "melinapn";
          };
        };
      in
      toString programScript;
    extraArgs = [ "--skip-login" ];
  };

  # Extra packages
  environment.systemPackages = with pkgs; [
    (cfwarp-add.override { substitutions = { "192.168.0.1" = "192.168.18.1"; }; })
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "24.11"; # Did you read the comment?
}
