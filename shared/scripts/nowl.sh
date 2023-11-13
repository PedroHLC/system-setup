#!/usr/bin/env sh

# These defaults to X11
unset CLUTTER_BACKEND
unset ECORE_EVAS_ENGINE
unset ELM_ENGINE
unset SDL_VIDEODRIVER
unset BEMENU_BACKEND
unset GTK_USE_PORTAL
unset NIXOS_OZONE_WL

# These needs explicit X11
export GDK_BACKEND='x11'
export XDG_SESSION_TYPE='x11'
export QT_QPA_PLATFORM='xcb'
export MOZ_ENABLE_WAYLAND=0

# If not sourced, run params
(return 0 2>/dev/null) || exec "$@"
