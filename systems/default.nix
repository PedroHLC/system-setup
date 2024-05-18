{ ssot, inputs }: with inputs;
let
  mkNixOS = { system, specs, extraModules ? [ ], specialArgs ? { } }: nixpkgs.lib.nixosSystem ({
    inherit system;

    specialArgs = inputs.self.specialArgs // specialArgs;

    modules = [
      chaotic.nixosModules.default
      ./core-configuration.nix
      home-manager.nixosModules.home-manager
      { home-manager.users.pedrohlc = import ../homes/pedrohlc (import specs); }
    ] ++ extraModules;
  });
in
{
  "${ssot.vpn.laptop.hostname}" = mkNixOS {
    system = "x86_64-linux";
    specs = ./laptop/specs.nix;
    extraModules = [
      impermanence.nixosModules.impermanence
      ../shared/config/wireguard-client.nix
      ../shared/config/wgcf-teams.nix
      ../shared/modules/focus.nix
      ./seat-configuration.nix
      ./laptop/hardware-configuration.nix
      ./laptop/configuration.nix
    ];
  };

  "${ssot.vpn.desktop.hostname}" = mkNixOS {
    system = "x86_64-linux";
    specs = ./desktop/specs.nix;
    extraModules = [
      impermanence.nixosModules.impermanence
      ../shared/config/4k-nohidpi.nix
      ../shared/config/journal-upload.nix
      ../shared/config/wireguard-client.nix
      ../shared/config/wgcf-teams.nix
      ../shared/modules/focus.nix
      ./seat-configuration.nix
      ./desktop/hardware-configuration.nix
      ./desktop/configuration.nix
    ];
  };

  "${ssot.vpn.lab.hostname}" = mkNixOS {
    system = "aarch64-linux";
    specs = ./vps-lab/specs.nix;
    extraModules = [
      (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
      (nixpkgs + "/nixos/modules/virtualisation/oci-common.nix")
      ./vps-lab/configuration.nix
      ./vps-lab/servers/adguard.nix
      ./vps-lab/servers/ctr.nix
      ./vps-lab/servers/git.nix
      ./vps-lab/servers/journal-remote.nix
      ./vps-lab/servers/matrix.nix
      ./vps-lab/servers/nginx.nix
      #./vps-lab/servers/runners.nix
      ./vps-lab/servers/wireguard.nix
      ./vps-lab/services/gits-mirror
      ./vps-lab/services/mesa-mirror
    ];
    specialArgs.knownClients = with nixpkgs.lib; rec {
      goodGuys = import ../shared/config/good-guys.nix ssot;
      badBotsCIDRs = trivial.importJSON ../shared/assets/bad-bots.json;
      goodGuysCIDRs = builtins.concatLists (map ({ ids, ... }: ids) goodGuys);
    };
  };
}
