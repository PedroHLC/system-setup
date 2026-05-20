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

  # includes newer protocols
  xdg-desktop-portal-wlr = final.xdg-desktop-portal-wlr_git;

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

  # until nixpkgs#518535
  tidal-hifi =
    if prev.tidal-hifi.version == "6.3.1-Mavy" then
      (prev.tidal-hifi.overrideAttrs (prevAttrs: rec {
        version = "7.0.1";
        src = final.fetchFromGitHub {
          owner = "Mastermindzh";
          repo = "tidal-hifi";
          tag = version;
          hash = "sha256-6RKGSXWe3YP52bv03kEX60RLE+WRBEsou6yHLZGEVPs=";
        };
        npmDepsHash = "sha256-8uDzikiVGLjhpba6HpSHcvlNghRtmugqjazoAYP1M98=";
        npmDeps = final.fetchNpmDeps {
          inherit src;
          hash = npmDepsHash;
          forceGitDeps = true;
          makeCacheWritable = true;
        };
      })).override
        {
          castlabs-electron = prev.tidal-hifi.passthru.castlabs-electron.overrideAttrs (prevAttrs: rec {
            version = "41.5.0";
            urls = [ "https://github.com/castlabs/electron-releases/releases/download/v${version}+wvcus/electron-v${version}+wvcus-linux-x64.zip" ];
            hash = "sha256-LjM80c48AzEwoU8h07qUELTV5jjQeApanaoPZ/szdag=";
          });
        }
    else throw "Newer tida-hifi in Nixpkgs";
}
