final: prev:

# Add pipewire-output
prev.audacious.override (oi: {
  audacious-plugins = oi.audacious-plugins.overrideAttrs (oa: {
    buildInputs = oa.buildInputs ++ [ final.pipewire ];
    patches = (oa.patches or [ ]) ++ [
      (final.fetchpatch {
        url = "https://github.com/audacious-media-player/audacious-plugins/pull/104/commits/ceeb649b8b8b5e6028db744aefaba7c59c798950.patch";
        hash = "sha256-YJxw9mdCQn9l9WbDuDLlQlIAwb3wZS/VLEzXUZGHctM=";
      })
    ];
  });
})
