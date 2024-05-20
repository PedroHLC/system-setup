utils: with utils;

mkIf hasSeat {
  # Merge Audacious public config with the secrets
  home.activation.mergeAudacious = hm.dag.entryAfter [ "onFilesChange" ] ''
    audConfig="$HOME/.config/audacious/config"
    if [[ ! -e "$audConfig" ]]; then
      $DRY_RUN_CMD touch "$audConfig"
      $DRY_RUN_CMD chmod 600 "$audConfig"
      $DRY_RUN_CMD cat "$audConfig.hm" > "$audConfig"
      $DRY_RUN_CMD cat "$HOME/.secrets/audacious.config" >> "$audConfig"
    fi

    audPlugin="$HOME/.config/audacious/plugin-registry"
    if [[ ! -e "$audPlugin" ]]; then
      $DRY_RUN_CMD cp "$audPlugin.hm" "$audPlugin"
      $DRY_RUN_CMD chmod 600 "$audPlugin"
    fi
  '';

  xdg = {
    # Audacious rice
    configFile = {
      audacious-config = {
        target = "audacious/config.hm";
        onChange = ''
          [[ -f "$HOME/.config/audacious/config" ]] && rm "$HOME/.config/audacious/config"
        '';
        text = audaciousConfigGenerator {
          audacious = {
            shuffle = false;
          };
          pipewire = {
            volume_left = 100;
            volume_right = 100;
          };
          resample = {
            default-rate = 96000;
            method = 0;
          };
          skins = {
            always_on_top = true;
            playlist_visible = false;
            skin = "${homePath}/.local/share/audacious/Skins/135799-winamp_classic";
          };
        };
      };
      audacious-plugin-registry = {
        target = "audacious/plugin-registry.hm";
        onChange = ''
          [[ -f "$HOME/.config/audacious/plugin-registry" ]] && rm "$HOME/.config/audacious/plugin-registry"
        '';
        # from: grep --no-group-separator -B9 'enabled 1' ~/.config/audacious/plugin-registry
        text =
          let
            audaciousLib = "${pkgs.audacious}/lib/audacious";
          in
          ''
            transport ${audaciousLib}/Transport/gio.so
            stamp 1
            version 48
            flags 0
            name GIO Plugin
            domain audacious-plugins
            priority 0
            about 1
            config 0
            enabled 1
            transport ${audaciousLib}/Transport/mms.so
            stamp 1
            version 48
            flags 0
            name MMS Plugin
            domain audacious-plugins
            priority 0
            about 0
            config 0
            enabled 1
            transport ${audaciousLib}/Transport/neon.so
            stamp 1
            version 48
            flags 0
            name Neon HTTP/HTTPS Plugin
            domain audacious-plugins
            priority 0
            about 0
            config 0
            enabled 1
            playlist ${audaciousLib}/Container/audpl.so
            stamp 1
            version 48
            flags 0
            name Audacious Playlists (audpl)
            domain audacious-plugins
            priority 0
            about 0
            config 0
            enabled 1
            playlist ${audaciousLib}/Container/cue.so
            stamp 1
            version 48
            flags 0
            name Cue Sheet Plugin
            domain audacious-plugins
            priority 0
            about 0
            config 0
            enabled 1
            playlist ${audaciousLib}/Container/m3u.so
            stamp 1
            version 48
            flags 0
            name M3U Playlists
            domain audacious-plugins
            priority 0
            about 0
            config 0
            enabled 1
            input ${audaciousLib}/Input/aac-raw.so
            stamp 1
            version 48
            flags 0
            name AAC (Raw) Decoder
            domain audacious-plugins
            priority 5
            about 0
            config 0
            enabled 1
            input ${audaciousLib}/Input/cdaudio-ng.so
            stamp 1
            version 48
            flags 0
            name Audio CD Plugin
            domain audacious-plugins
            priority 5
            about 1
            config 1
            enabled 1
            input ${audaciousLib}/Input/madplug.so
            stamp 1
            version 48
            flags 0
            name MPG123 Plugin
            domain audacious-plugins
            priority 5
            about 0
            config 1
            enabled 1
            input ${audaciousLib}/Input/opus.so
            stamp 1
            version 48
            flags 0
            name Opus Decoder
            domain audacious-plugins
            priority 5
            about 1
            config 0
            enabled 1
            input ${audaciousLib}/Input/wavpack.so
            stamp 1
            version 48
            flags 0
            name WavPack Decoder
            domain audacious-plugins
            priority 5
            about 1
            config 0
            enabled 1
            input ${audaciousLib}/Input/flacng.so
            stamp 1
            version 48
            flags 0
            name FLAC Decoder
            domain audacious-plugins
            priority 6
            about 1
            config 0
            enabled 1
            input ${audaciousLib}/Input/vorbis.so
            stamp 1
            version 48
            flags 0
            name Ogg Vorbis Decoder
            domain audacious-plugins
            priority 7
            about 1
            config 0
            enabled 1
            effect ${audaciousLib}/Effect/resample.so
            stamp 1
            version 48
            flags 0
            name Sample Rate Converter
            domain audacious-plugins
            priority 2
            about 1
            config 1
            enabled 1
            output ${audaciousLib}/Output/pipewire.so
            stamp 1
            version 48
            flags 0
            name PipeWire Output
            domain audacious-plugins
            priority 2
            about 1
            config 0
            enabled 1
            general ${audaciousLib}/General/mpris2.so
            stamp 1
            version 48
            flags 0
            name MPRIS 2 Server
            domain audacious-plugins
            priority 0
            about 0
            config 0
            enabled 1
            general ${audaciousLib}/General/scrobbler.so
            stamp 1
            version 48
            flags 0
            name Scrobbler 2.0
            domain audacious-plugins
            priority 0
            about 1
            config 1
            enabled 1
            iface ${audaciousLib}/General/skins-qt.so
            stamp 1
            version 48
            flags 2
            name Winamp Classic Interface
            domain audacious-plugins
            priority 0
            about 0
            config 1
            enabled 1
          '';
      };
    };
    # Other data files
    dataFile = {
      audaciousSkinWinampClassic = {
        target = "audacious/Skins/135799-winamp_classic";
        source = pkgs.audacious-skin-winamp-classic;
      };
    };
  };
}
