{
  description = "PedroHLC's NixOS Flake";

  # My main channel and extra repositories
  inputs = {
    nixpkgs.follows = "chaotic/nixpkgs";

    # reset rootfs every reboot
    impermanence.url = "https://flakehub.com/f/nix-community/impermanence/0.1.*.tar.gz";

    # home-manager for managing my users' home
    home-manager.follows = "chaotic/home-manager";

    # stuff I use for infecting my home
    yafas.follows = "chaotic/yafas";

    # Smooth-criminal bleeding-edge packages
    chaotic.url = "https://flakehub.com/f/chaotic-cx/nyx/0.1.*.tar.gz";

    # My FFx userChrome.css
    pedrochrome-css = {
      url = "git+https://gist.github.com/3c52f40134eeadf689d6269f271c755b.git";
      flake = false;
    };

    # The Crash Team Racing decomp
    ctr = {
      url = "github:ClaudioBo/CTR-ModSDK";
      inputs.nixpkgs.follows = "chaotic/nixpkgs";
      inputs.yafas.follows = "chaotic/yafas";
      inputs.systems.follows = "chaotic/systems";
    };

    # Functional-programming lib
    fp-lib.url = "github:PedroHLC/nix-ullib";

    # Experimental flavor
    stylix = {
      url = "github:danth/stylix";
      inputs.flake-compat.follows = "chaotic/flake-compat";
      inputs.home-manager.follows = "chaotic/home-manager";
      inputs.nixpkgs.follows = "chaotic/nixpkgs";
    };
  };

  outputs = { nixpkgs, yafas, chaotic, fp-lib, ... }@inputs:
    let
      ssot = import ./shared/ssot.nix inputs;
    in
    yafas.withAllSystems nixpkgs
      (universals: { pkgs, system }: with universals; {
        # Defines a formatter for "nix fmt"
        formatter = pkgs.nixpkgs-fmt;

        # A package that applies my HM to anything
        packages.pedrohlc-hm-infect = import ./homes/infect.nix { inherit pkgs ssot inputs; };
      })
      {
        # My systems
        nixosConfigurations = import ./systems { inherit ssot inputs; };
        # Special args you'll find in every module.
        specialArgs = {
          inherit ssot;
          flakes = inputs;
        };
        # When accessing my flake from other computers I need chaotic's cache
        inherit (chaotic) nixConfig;
      };
}

