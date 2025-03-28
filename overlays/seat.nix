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

  # Allow bluetooth management easily in sway
  fzf-bluetooth = final.callPackage ../packages/fzf-bluetooth.nix { };

  # helps me adding routes to CF WARP
  cfwarp-add = final.callPackage ../packages/scripts { scriptName = "cfwarp-add"; };

  # helps me connecting to some VPS
  ssh-to-nix = final.callPackage ../packages/scripts { scriptName = "ssh-to-nix"; };

  # includes newer protocols
  xdg-desktop-portal-wlr = final.xdg-desktop-portal-wlr_git;

  # newer version
  nut = final.nut_git;

  # https://tildearrow.org/?p=post&month=7&year=2022&item=lar
  hostapd_nolar = final.hostapd.overrideAttrs (oa: {
    patches = [
      (final.fetchpatch { url = "https://tildearrow.org/storage/hostapd-2.10-lar.patch"; hash = "sha256-USiHBZH5QcUJfZSxGoFwUefq3ARc4S/KliwUm8SqvoI="; })
    ];
  });

  # Contains -srgb parameter
  uxplay = prev.uxplay.overrideAttrs (oa: {
    src = final.fetchFromGitHub {
      owner = "FDH2";
      repo = "UxPlay";
      rev = "bccc42e4e25c7f79efbb14ac2bf1fcb55718ee64";
      hash = "sha256-46hYjmoiykw/sbjU9+6ZdQNOY2k4pIA7w8TRNrG76ck=";
    };
  });

  # https://github.com/NixOS/nixpkgs/issues/380439
  vimix-icon-theme = prev.vimix-icon-theme.overrideAttrs (_oa: {
    dontCheckForBrokenSymlinks = true;
  });
}
