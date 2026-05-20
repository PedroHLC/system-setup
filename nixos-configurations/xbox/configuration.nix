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

  # Autologin (with Melina).
  services.getty.loginOptions =
    let
      programScript = pkgs.callPackage ../../packages/login-program.nix {
        loginsPerTTY = {
          "/dev/tty1" = "pedrohlc";
          "/dev/tty2" = "melinapn";
        };
      };
    in
    lib.mkForce (toString programScript);

  boot.kernelParams = [
    "amdgpu.gpu_recovery=1"
    "amdgpu.lockup_timeout=5000"
    "amdgpu.runpm=0"
    # Let's use AMD P-State
    "amd-pstate=guided"
  ];

  # Enable all experimental
  environment.variables.RADV_EXPERIMENTAL = "heap,hic,transfer_queue";

  # Loads GPU earlier in boot
  boot.initrd.availableKernelModules = [ "amdgpu" ];

  # Extra packages
  environment.systemPackages = with pkgs; [
    (cfwarp-add.override { substitutions = { "192.168.0.1" = "192.168.18.1"; }; })
  ];

  # Feature set
  nix.settings.system-features = [
    # Allows building v4 packages
    "big-parallel"
    "gccarch-x86-64-v3"
    # Allows building Nixpkgs tests
    "kvm"
    "nixos-test"
  ];

  # Allows HDR gaming (AMD-GPU only).
  programs.steam.gamescopeSession.enable = true; # HDR can only be used with headless Gamescope right now...
  programs.gamescope = {
    args = [ "--hdr-enabled" ];
    env = {
      DXVK_HDR = "1";
    };
  };

  # ctrlNearSpaceKeyMap and swap [\|] with ['"] to mimic OSX
  services.udev.extraHwdb = ''
    evdev:input:b0003v0C45p767E*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_700E0=key_leftalt
      KEYBOARD_KEY_700E3=key_leftmeta
      KEYBOARD_KEY_700E2=key_leftctrl
      KEYBOARD_KEY_70035=key_102nd
      KEYBOARD_KEY_70064=key_grave
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "24.11"; # Did you read the comment?
}

