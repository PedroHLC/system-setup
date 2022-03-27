pkgs:
pkgs.writeShellScriptBin "nowl" ''
  unset CLUTTER_BACKEND
  unset ECORE_EVAS_ENGINE
  unset ELM_ENGINE
  unset SDL_VIDEODRIVER
  unset BEMENU_BACKEND
  unset GTK_USE_PORTAL
  unset NIXOS_OZONE_WL
  export GDK_BACKEND='x11'
  export XDG_SESSION_TYPE='x11'
  export QT_QPA_PLATFORM='xcb'
  export MOZ_ENABLE_WAYLAND=0
  exec -a "$0" "$@"
''
