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

  # Locale stuff
  # I've tried to set everything as I wanted using `home.language`, but locale/mosh/man only seem to accept LANG & LC_ALL.
  home.sessionVariables.LANG = "en_GB.UTF-8";
  home.sessionVariables.LC_ALL = "en_IE.UTF-8";

  # Unecessary
  programs.command-not-found.enable = false;

  # More packages
  home.packages = with pkgs; [
    aria2
    borg-sans-mono
    gnupg
    heroku
    home-manager
    lan-mouse_git
    mosh
    ripgrep
    tmux
  ];

  # Borg Sans is good!
  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [ "Borg Sans Mono" ];
  };
}
