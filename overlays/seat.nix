final: prev: {
  # Obs with plugins
  obs-studio-wrapped = final.wrapOBS.override { inherit (final) obs-studio; } {
    plugins = with final.obs-studio-plugins; [
      obs-gstreamer
      obs-pipewire-audio-capture
      obs-vaapi
      obs-vkcapture
      wlrobs
    ];
  };

  # Helm with plugins
  kubernetes-helm-wrapped = final.wrapHelm
    (prev.kubernetes-helm.overrideDerivation (oa: {
      patches = [
        (final.fetchpatch {
          url = "https://github.com/PedroHLC/helm/commit/0144b70c0ef66877637c37a4211cb430f1e61e33.patch";
          hash = "sha256-2BHv8QvVijlN7UVC6zoLsTI1o7HQlafuDeoGb2WpVGw=";
        })
      ] ++ oa.patches;
    }))
    { plugins = with final.kubernetes-helmPlugins; [ helm-diff ]; };

  # Steam in tenfoot + mangoapp
  bigsteam = final.callPackage ../packages/scripts { scriptName = "bigsteam"; };

  # Gamemoderun + mangoapp (to run withing gamescope)
  mangoapprun = final.callPackage ../packages/scripts { scriptName = "mangoapprun"; };

  # Script to force XWayland (in case something catches fire).
  nowl = final.callPackage ../packages/scripts { scriptName = "nowl"; };

  # Environment to properly (and force) use wayland.
  wayland-env = final.callPackage ../packages/scripts { scriptName = "wayland-env"; };

  # Audacious rice
  audacious-skin-winamp-classic = final.callPackage ../packages/audacious-skin-winamp-classic.nix { };

  # Anime4K shaders
  anime4k = final.callPackage ../packages/anime4k.nix { };

  # for 60fps anime
  mpv-vapoursynth =
    (final.mpv.override {
      mpv-unwrapped = final.mpv-unwrapped.override {
        vapoursynthSupport = true;
        vapoursynth = final.vapoursynth.withPlugins [ final.vapoursynth-mvtools ];
      };
    });

  # Allow bluetooth management easily in sway
  fzf-bluetooth = final.callPackage ../packages/fzf-bluetooth.nix { };

  # helps me adding routes to CF WARP
  cfwarp-add = final.callPackage ../packages/scripts { scriptName = "cfwarp-add"; };

  # helps me connecting to some VPS
  ssh-to-nix = final.callPackage ../packages/scripts { scriptName = "ssh-to-nix"; };

  # includes https://github.com/emersion/xdg-desktop-portal-wlr/pull/325
  xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs ++ [ final.libxkbcommon ];
    patches =
      if prevAttrs.src.rev == "v0.8.1" then [
        (final.fetchpatch2 {
          url = "https://github.com/${prevAttrs.src.owner}/${prevAttrs.src.repo}/compare/v0.8.1..925dcc3fe681f3e595e9e44eb5372163fc41ad70.diff";
          hash = "sha256-pHeY0OcT5VMaknRUo1PhkeoHEu4gF8ewklN4IqjCcfs=";
        })
      ] else throw "I BELIEVE THEM BONES ARE ME!";
    postPatch = "
      substituteInPlace src/core/config.c --replace-fail 'bool is_allowed;' 'bool is_allowed = false;'
    ";
  });

  # https://tildearrow.org/?p=post&month=7&year=2022&item=lar
  hostapd_nolar = final.hostapd.overrideAttrs (oa: rec {
    version = "2.10";
    src = final.fetchurl {
      url = "https://w1.fi/releases/${oa.pname}-${version}.tar.gz";
      hash = "sha256-IG58eZtnhXLC49EgMCOHhLxKn4IyOwFWtMlGbxSYkV0=";
    };
    patches = [
      (final.fetchpatch { url = "https://tildearrow.org/storage/hostapd-2.10-lar.patch"; hash = "sha256-USiHBZH5QcUJfZSxGoFwUefq3ARc4S/KliwUm8SqvoI="; })
    ];
  });

  # figma-linux needs mimeTypes
  figma-linux = prev.figma-linux.overrideAttrs (_oa: {
    desktopItems = [
      (final.makeDesktopItem {
        name = "figma-linux";
        desktopName = "Figma Linux";
        comment = "Unofficial Figma desktop application for Linux";
        exec = "figma-linux %U";
        icon = "figma-linux";
        terminal = false;

        startupWMClass = "figma-linux";
        type = "Application";
        mimeTypes = [ "x-scheme-handler/figma" "application/figma" ];
      })
    ];
  });

  # gaming at full speed
  proton-cachyos = final.callPackage ../packages/proton-bin {
    toolTitle = "Proton-CachyOS";
    tarballPrefix = "proton-";
    tarballSuffix = "-x86_64.tar.xz";
    toolPattern = "proton-cachyos-.*";
    releasePrefix = "cachyos-";
    releaseSuffix = "-slr";
    versionFilename = "cachyos-version.json";
    owner = "CachyOS";
    repo = "proton-cachyos";
  };
  proton-cachyos_x86_64_v3 = final.proton-cachyos.override {
    toolTitle = "Proton-CachyOS x86-64-v3";
    tarballSuffix = "-x86_64_v3.tar.xz";
    versionFilename = "cachyos-v3-version.json";
  };

  # https://github.com/NixOS/nixpkgs/pull/451951
  osdlyrics = (prev.osdlyrics).overrideAttrs (prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
      final.gobject-introspection
      final.wrapGAppsNoGuiHook
    ];

    env.NIX_CFLAGS_COMPILE = "-Wno-incompatible-pointer-types";

    dontWrapGApps = true;

    preFixup = ''
      makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
    '';

    postFixup = builtins.replaceStrings [ "wrapProgram \"$p\"" ] [ "wrapProgram \"$p\" \"\${makeWrapperArgs[@]}\"" ] prevAttrs.postFixup;
  });
}
