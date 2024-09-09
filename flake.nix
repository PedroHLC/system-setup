{
  description = "PedroHLC's NixOS Flake";

  # My main channel and extra repositories
  inputs = {
    nixpkgs.follows = "chaotic/nixpkgs";
    nixpkgs-old.url = "github:NixOS/nixpkgs/693bc46d169f5af9c992095736e82c3488bf7dbb";

    # Reset rootfs every reboot
    impermanence.url = "https://flakehub.com/f/nix-community/impermanence/0.1.*.tar.gz";

    # Home-manager for managing my user's home
    home-manager.follows = "chaotic/home-manager";

    # My "outputs" manager
    yafas.url = "github:UbiqueLambda/yafas";

    # Smooth-criminal bleeding-edge packages
    chaotic.url = "https://flakehub.com/f/chaotic-cx/nyx/0.1.*.tar.gz";

    # My FFx userChrome.css
    pedrochrome-css = {
      url = "git+https://gist.github.com/3c52f40134eeadf689d6269f271c755b.git";
      flake = false;
    };

    # The Crash Team Racing decomp
    ctr = {
      url = "github:CTR-tools/CTR-ModSDK";
      inputs.nixpkgs.follows = "chaotic/nixpkgs";
      inputs.yafas.follows = "yafas";
    };

    # Functional-programming lib
    fp-lib.url = "github:PedroHLC/nix-ullib";

    # Experimental flavor
    stylix = {
      url = "github:danth/stylix";
      inputs.home-manager.follows = "chaotic/home-manager";
      inputs.nixpkgs.follows = "chaotic/nixpkgs";
    };
  };

  outputs = { nixpkgs, yafas, chaotic, fp-lib, ... }@inputs:
    yafas.withAllSystems nixpkgs
      (universals: { pkgs, system }@sys: with universals; {
        # Defines a formatter for "nix fmt"
        formatter = pkgs.nixpkgs-fmt;

        # A package that applies my HM to anything
        packages = import ./packages (specialArgs // sys);
      })
      rec {
        # My systems
        nixosConfigurations = import ./nixos/configurations specialArgs;

        # Special args you'll find in every module.
        specialArgs = {
          ssot = import ./assets/ssot.nix inputs;
          flakes = inputs;
        };

        # When accessing my flake from other computers I need chaotic's cache
        inherit (chaotic) nixConfig;
      };
}
