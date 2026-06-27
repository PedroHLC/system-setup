{
  description = "PedroHLC's NixOS Flake";

  # My main channel and extra repositories
  inputs = {
    # Godsent flake
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # Mortal-hands flake
    nixpkgs.follows = "chaotic/nixpkgs";

    # Reset rootfs every reboot
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # Home-manager for managing my user's home
    home-manager.follows = "chaotic/home-manager";

    # My "outputs" manager
    yafas.url = "github:UbiqueLambda/yafas";

    # My FFx userChrome.css
    pedrochrome-css = {
      url = "git+https://gist.github.com/3c52f40134eeadf689d6269f271c755b.git";
      flake = false;
    };

    # Functional-programming lib
    ullib.url = "github:PedroHLC/nix-ullib";

    # Experimental flavor
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Latest Claude
    latest-claude-code = {
      url = "github:NixOS/nixpkgs?dir=pkgs/by-name/cl/claude-code";
      flake = false;
    };

    # Modern terminal multiplexer
    herdr = {
      url = "github:ogulcancelik/herdr/dbc45f6306bda3eee681d73a14b48ffbb39f3fcc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, yafas, chaotic, ... }@inputs:
    let
      flakes = inputs // { inherit (chaotic.vendored) jovian niks3; };
    in
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
        specialArgs = import common/nixos-special-args.nix flakes;

        # When accessing my flake from other machines I need chaotic's cache
        inherit (inputs.chaotic) nixConfig;
      };
}
