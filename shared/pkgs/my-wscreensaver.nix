{ mpvpaper
, procps
, spotify-unwrapped
, swaylock-plugin_git
, writeShellScript
, writeShellScriptBin
}:

let
  screensaver = writeShellScript "my-wscreensaver-bg" ''
    ${mpvpaper}/bin/mpvpaper \
      -o '--ao=none --shuffle --loop-file=inf --scale=oversampl' \
      '*' \
      "''$@"
  '';
in
writeShellScriptBin "my-wscreensaver" ''
  PIDOF="${procps}/bin/pidof"
  _HAS_MUSIC=$("$PIDOF" ${spotify-unwrapped}/share/spotify/.spotify-wrapped)

  cd ~/Videos

  _MEDIA='horizontal.m3u'
  [[ $_HAS_MUSIC ]] && _MEDIA='with-music.m3u'

  ${swaylock-plugin_git}/bin/swaylock-plugin \
    --command "${screensaver} \"''$_MEDIA\""
''
