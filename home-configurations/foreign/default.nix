{ pkgs, lib, flakes, ... }: {
  home.stateVersion = "24.11";

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
    aerospace
    autoraise
    aria2
    borg-sans-mono
    dbeaver-bin
    gh
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

  # Aerospace agent
  launchd.agents.aerospace = {
    enable = true;
    config = {
      Label = "io.github.nikitabobko.aerospace";
      ProcessType = "Background";
      ProgramArguments = [ "/Users/pedrohlc/Applications/Home Manager Apps/AeroSpace.app/Contents/MacOS/AeroSpace" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  # AutoRaise agent
  launchd.agents.autoraise = {
    enable = true;
    config = {
      Label = "io.github.sbmpost.autoraise";
      ProcessType = "Background";
      ProgramArguments = [ "/Users/pedrohlc/Applications/Home Manager Apps/AutoRaise.app/Contents/MacOS/AutoRaise" "-delay" "2" ];
      RunAtLoad = true;
      KeepAlive.OtherJobEnabled."io.github.nikitabobko.aerospace" = true;
    };
  };


  # Make apps indexable
  home.activation.makeTrampolineApps = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    builtins.readFile ../../assets/make-app-trampolines.sh
  );

  # This is for reusing the versioned flakes inputs for CLI commands.
  # HomeManager does not provide `nixpkgs.flake.setNixPath`
  nix.nixPath = lib.mkDefault [ "nixpkgs=flake:nixpkgs" ];
  chaotic.nyx.registry.enable = true;
  chaotic.nyx.nixPath.enable = true;
}
