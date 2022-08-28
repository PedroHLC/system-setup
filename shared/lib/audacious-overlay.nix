final: prev:

# Add pipewire-output
prev.audacious.override (oldInputs: {
  audacious-plugins = oldInputs.audacious-plugins.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ final.pipewire ];
    src = final.fetchFromGitHub {
      owner = "audacious-media-player";
      repo = "audacious-plugins";
      rev = "5a4a5783c2e9c3a08a766aa6e96c8d616f80f444";
      hash = "sha256-WleMEsVY64RLtTGozdNw8n8wZI14a7btBt0NHV4gkDM=";
    };
  });
})
