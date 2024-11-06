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

  # Locale stuff (Must match system)
  home.language = {
    base = "en_IE.UTF8";
    ctype = "en_UK.UTF-8";

    address = "pt_BR.UTF8";
    collate = "pt_BR.UTF8";
    measurement = "pt_BR.UTF8";
    messages = "en_US.UTF-8";
    monetary = "pt_BR.UTF8";
    name = "pt_BR.UTF8";
    numeric = "pt_BR.UTF8";
    paper = "pt_BR.UTF8";
    telephone = "pt_BR.UTF8";
    time = "pt_BR.UTF8";
  };

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
