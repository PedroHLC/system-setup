{ pkgs, flakes, ... }: {
  home.stateVersion = "24.05";

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes

      keep-outputs = true
      keep-derivations = true
    '';

    # Always uses system's flakes instead of downloading or updating.
    registry = {
      nixpkgs.flake = flakes.nixpkgs;
      chaotic.flake = flakes.chaotic;
    };
  };

  # Unecessary
  programs.command-not-found.enable = false;

  # More packages
  home.packages = with pkgs; [
    borg-sans-mono
    gnupg
    heroku
    home-manager
    # Waiting nixpkgs#350035
    # mosh
  ];

  # Borg Sans is good!
  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [ "Borg Sans Mono" ];
  };
}
