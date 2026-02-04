{ mpvpaper
, procps
, swaylock
, swaylock-plugin
, writeShellScript
, writeShellScriptBin
}:

let
  screensaver = writeShellScript "my-wscreensaver-bg" ''
    ${mpvpaper}/bin/mpvpaper \
      -o '--ao=none --shuffle --loop-file=inf --scale=oversample' \
      '*' "''$@"
  '';
in
writeShellScriptBin "my-wscreensaver" ''
  if [[ -e /sys/class/power_supply/BAT0 ]] &&
    [[ $(cat /sys/class/power_supply/AC0/online) != 1 ]]; then
    exec ${swaylock}/bin/swaylock -s fit -i ~/Pictures/nvidia-meme.jpg
  else
    PIDOF="${procps}/bin/pidof"
    _HAS_MUSIC=$("$PIDOF" tidal-hifi)

    cd ~/Videos

    _MEDIA='horizontal.m3u'
    [[ $_HAS_MUSIC ]] && _MEDIA='with-music.m3u'

    exec ${swaylock-plugin}/bin/swaylock-plugin \
      --command "${screensaver} \"''$_MEDIA\""
  fi
''
