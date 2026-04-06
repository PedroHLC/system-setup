{ config, pkgs, lib, ... }:
{
  # An attempt to start SteamRT3 directly
  programs.nix-ld.systems =
    let
      getPkgs = archPkgs: with archPkgs; [
        # First phase
        glib
        # Second phase
        libcap
        # Third phase
        vulkan-loader
        libx11
        libva
        # Fourth phase
        libxcb
        libvdpau
        # Fifth phase
        libGL
        # Sixth phase
        libxrandr
        # Etc
        libgbm
        mesa
        # Very nearby running it
        libxtst
        libxfixes
        libxrender
        libxext
      ];

      archSet = archPkgs: {
        enable = true;
        pkgs = archPkgs;
        libraries = getPkgs archPkgs;
      };
    in
    {
      x86_64-linux = archSet pkgs;
      i686_linux = archSet pkgs.pkgsi686Linux // { ldso = "ldso32"; };
    };

  environment.variables = {
    # SRT_EXTRA_LIBRARY_PATH = lib.makeLibraryPath (config.programs.nix-ld.systems.x86_64-linux.libraries ++ config.programs.nix-ld.systems.i686_linux.libraries);
    STEAM_DEBUG = "1";
    SRT_LOG = "debug";
    PRESSURE_VESSEL_LOG_LEVEL = "debug";
    TEXTDOMAINDIR = "/run/current-system/sw/share/locale";
  };
}
#export STEAM_DEBUG=1 SRT_LOG=debug PRESSURE_VESSEL_LOG_LEVEL=debug
#export TEXTDOMAIN=steam TEXTDOMAINDIR=/run/current-system/sw/share/locale STEAMROOT=/home/pedrohlc/.local/share/Steam STEAMDATA=/home/pedrohlc/.local/share/Steam STEAMEXE=steam MAGIC_RESTART_EXITCODE=42
#export STEAMSCRIPT=/home/pedrohlc/.local/share/Steam/steam.sh
