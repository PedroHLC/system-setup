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
    ./servers/bsky.nix
    ./servers/ctr.nix
    ./servers/git.nix
    ./servers/journal-remote.nix
    ./servers/matrix.nix
    ./servers/nginx.nix
    #./servers/runners.nix
    ./servers/wireguard.nix
    ./services/gits-mirror
    ./services/ical-filter
    ./services/mesa-mirror
  ];
  extraConfig = {
    # Mautrix uses OLM
    permittedInsecurePackages = [
      "olm-3.2.16"
    ];
  };
  specialArgs.knownClients = with nixpkgs.lib; rec {
    goodGuys = import ../../common/good-guys.nix ssot;
    badBotsCIDRs = trivial.importJSON ../../assets/bad-bots.json;
    goodGuysCIDRs = builtins.concatLists (map ({ ids, ... }: ids) goodGuys);
  };
}
