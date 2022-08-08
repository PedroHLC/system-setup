final: prev:

# 1. Add pipewire-output
# 2. Add missing qtx11extras
# 3. Add autoconf & automake (autoreconfHook) for triggering pipewire-output build
prev.audacious.overrideAttrs (oa:
{
  nativeBuildInputs = oa.nativeBuildInputs ++ [ final.autoreconfHook ];
  buildInputs = oa.buildInputs ++ [ final.pipewire final.libsForQt5.qtx11extras ];
  pluginsSrc = final.stdenvNoCC.mkDerivation {
    name = "audacious-plugins-source";
    src = oa.pluginsSrc;

    patches = [
      (final.fetchpatch {
        url = "https://github.com/audacious-media-player/audacious-plugins/pull/104/commits/ceeb649b8b8b5e6028db744aefaba7c59c798950.patch";
        hash = "sha256-YJxw9mdCQn9l9WbDuDLlQlIAwb3wZS/VLEzXUZGHctM=";
      })
    ];

    phases = [ "unpackPhase" "patchPhase" "installPhase" ]; # dontBuild was ignored
    sourceRoot = "./audacious-plugins-4.2";

    installPhase = ''
      install -dm 755 "$out"
      cp -dr * "$out/"
    '';
  };
})
