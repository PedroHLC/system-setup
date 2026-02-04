{
  description = "PedroHLC's NixOS Flake";

  # My main channel and extra repositories
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Reset rootfs every reboot
    impermanence.url = "github:nix-community/impermanence";

    # Home-manager for managing my user's home
    home-manager.url = "github:nix-community/home-manager";

    # My "outputs" manager
    yafas.url = "github:UbiqueLambda/yafas";

    # My FFx userChrome.css
    pedrochrome-css = {
      url = "git+https://gist.github.com/3c52f40134eeadf689d6269f271c755b.git";
      flake = false;
    };

    # The Crash Team Racing decomp
    ctr = {
      url = "github:CTR-tools/CTR-ModSDK";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.yafas.follows = "yafas";
    };

    # Functional-programming lib
    ullib.url = "github:PedroHLC/nix-ullib";

    # Experimental flavor
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, yafas, ... }@inputs:
    yafas.withAllSystems nixpkgs
      (universals: { pkgs, system }@sys: with universals; {
        # Defines a formatter for "nix fmt"
        formatter = pkgs.nixpkgs-fmt;

        # A package that applies my HM to anything
        packages = import ./packages (specialArgs // sys);
      })
      rec {
        # My systems
        nixosConfigurations = import ./nixos-configurations specialArgs;

        # Home for HM-installed systems
        homeConfigurations = import ./home-configurations specialArgs;

        # Special args you'll find in every module.
        specialArgs = import common/nixos-special-args.nix inputs;
      };
}
