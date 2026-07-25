{ flakes, config, pkgs, lib, ... }:
{
  # An attempt to start SteamRT3 directly

  # Needs nix-ld for invoking $STEAMROOT/steamrt64/pv-runtime/steam-runtime-steamrt/bin/*
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
        # If it works, you should not need these:
        #libxtst
        #libxfixes
        #libxrender
        #libxext
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
    SRT_EXTRA_LIBRARY_PATH = "/nix:/run/current-system:/run/opengl-driver:/run/opengl-driver-32:/run/wrappers";
    TEXTDOMAINDIR = "/run/current-system/sw/share/locale";

    # Debug
    STEAM_DEBUG = "1";
    SRT_LOG = "debug";
    PRESSURE_VESSEL_LOG_LEVEL = "debug";
    STEAM_RUNTIME_LOGGER = "1"; # writes to logs/console-linux.txt
  };

  # Steam prefer these binaries when found in host
  environment.systemPackages = with pkgs; [
    zenity
  ];

  # Borked shebang in $STEAMROOT/steamrt64/pv-run.sh
  # They test bwrap with a `exec true` without PATH (probably not really needed)
  system.activationScripts.steam-rt-requirements = ''
    ln -sfn ${pkgs.bash}/bin/bash /bin/bash
    ln -sfn ${pkgs.coreutils}/bin/true /bin/true
    mkdir -m 0755 -p /var/cache/ldconfig
    ${pkgs.glibc}/bin/ldconfig -C /var/cache/ldconfig/ld.so.cache -f /dev/null
  '';

  # in case of contamination
  #programs.steam.enable = lib.mkForce false;

  # replaces nix-ld with a multilib compatible
  disabledModules = [ "${flakes.nixpkgs}/nixos/modules/programs/nix-ld.nix" ];
  imports = [ (import "${flakes.nix-ld-32bit}/nix-ld.nix") ];
}
# export TEXTDOMAIN=steam STEAMROOT=$HOME/.local/share/Steam STEAMDATA=$STEAMROOT STEAMEXE=steam MAGIC_RESTART_EXITCODE=42 STEAMSCRIPT=$STEAMROOT/steam.sh
# - The file that controls if steam starts with SteamRT
# touch $STEAMROOT/.steam-enable-steamrt64-client
# strings $STEAMROOT/steamrt64/pv-runtime/steam-runtime-steamrt/pressure-vessel/bin/pressure-vessel-wrap | grep -P '^[A-Z_]+$' | sort -u | less
# - The debugging way to test starting steam
# bash -x $STEAMROOT/steam.sh
# - Also able to test some commands in pressure-vessel like:
# $STEAMROOT/steamrt64/pv-run.sh -- bash -c '[ -f /lib/x86_64-linux-gnu/libEGL_mesa.so.0 ] && echo OK'
# export VK_DRIVER_FILES='/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json'
# $STEAMROOT/steamrt64/pv-run.sh -- vkcube
# - A very weird way to start a terminal
# $STEAMROOT/steamrt64/pv-run.sh -- env \
#   LD_LIBRARY_PATH="/overrides/lib/x86_64-linux-gnu/aliases:/overrides/lib/i386-linux-gnu/aliases:/overrides/lib/x86_64-linux-gnu/:/overrides/lib/i386-linux-gnu:/lib:/usr/lib/pressure-vessel/from-host/lib/x86_64-linux-gnu:/usr/lib/pressure-vessel/from-host/lib/i386-linux-gnu:/lib/x86_64-linux-gnu:/lib/i386-linux-gnu" \
#   LD_PRELOAD="$STEAMROOT/steamrt64/steam-runtime-steamrt/var/tmp-J2NOP3/usr/lib/pressure-vessel/overrides/lib/x86_64-linux-gnu/libpthread.so.0:$STEAMROOT/steamrt64/steam-runtime-steamrt/var/tmp-J2NOP3/usr/lib/pressure-vessel/overrides/lib/x86_64-linux-gnu/librt.so.1" \
#   xterm
