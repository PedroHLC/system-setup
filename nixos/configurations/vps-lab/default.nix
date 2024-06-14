{ ssot, flakes, mkNixOS, ... }: with flakes;

mkNixOS {
  system = "aarch64-linux";
  specs = ./specs.nix;
  extraModules = [
    "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
    "${nixpkgs}/nixos/modules/virtualisation/oci-common.nix"
    ./configuration.nix
    ./servers/adguard.nix
    ./servers/atuin.nix
    ./servers/ctr.nix
    ./servers/git.nix
    ./servers/journal-remote.nix
    ./servers/matrix.nix
    ./servers/nginx.nix
    #./servers/runners.nix
    ./servers/wireguard.nix
    ./services/gits-mirror
    ./services/mesa-mirror
  ];
  specialArgs.knownClients = with nixpkgs.lib; rec {
    goodGuys = import ../../../assets/good-guys.nix ssot;
    badBotsCIDRs = trivial.importJSON ../../../assets/bad-bots.json;
    goodGuysCIDRs = builtins.concatLists (map ({ ids, ... }: ids) goodGuys);
  };
}
