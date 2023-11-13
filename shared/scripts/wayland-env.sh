# Force wayland overall.
export BEMENU_BACKEND='wayland'
export CLUTTER_BACKEND='wayland'
export ECORE_EVAS_ENGINE='wayland_egl'
export ELM_ENGINE='wayland_egl'
export GDK_BACKEND='wayland'
export MOZ_ENABLE_WAYLAND=1
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_QPA_PLATFORM='wayland-egl'
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export SAL_USE_VCLPLUGIN='gtk3'
export SDL_VIDEODRIVER='wayland'
export _JAVA_AWT_WM_NONREPARENTING=1
export NIXOS_OZONE_WL=1

# If not sourced, run params
(return 0 2>/dev/null) || exec "$@"
