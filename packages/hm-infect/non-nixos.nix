{ pkgs, flakes, ... }: {
  home.stateVersion = "23.11";

  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # Always uses system's flakes instead of downloading or updating.
    registry = {
      nixpkgs.flake = flakes.nixpkgs;
      chaotic.flake = flakes.chaotic;
    };
  };

  # Unecessary
  programs.command-not-found.enable = false;

  # save some space
  manual.manpages.enable = false;
}
