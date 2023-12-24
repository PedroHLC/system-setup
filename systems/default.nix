{ ssot, inputs }: with inputs;
let
  mkNixOS = { system, specs, extraModules ? [ ] }: nixpkgs.lib.nixosSystem ({
    inherit system;
    inherit (inputs.self) specialArgs;

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
      ./vps-lab/servers/journal-remote.nix
      ./vps-lab/servers/libreddit.nix
      ./vps-lab/servers/matrix.nix
      ./vps-lab/servers/nginx.nix
      ./vps-lab/servers/runners.nix
      ./vps-lab/servers/wireguard.nix
      ./vps-lab/services/mesa-mirror
    ];
  };
}
