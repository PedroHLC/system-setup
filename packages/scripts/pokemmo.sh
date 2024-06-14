#!/usr/bin/env sh
set -eu
cd ~/Games/PokeMMO

GAMEMODERUN=${GAMEMODERUN:-$(which gamemoderun)}
ALSALIB=${ALSALIB:-/run/current-system/sw/lib/libasound.so.2}
JAVA=${JAVA:-$(which java)}

exec "$GAMEMODERUN" \
  LD_PRELOAD="$ALSALIB:$LD_PRELOAD" ALSOFT_DRIVERS="alsa" \
  "$JAVA" -Dfile.encoding="UTF-8" -cp PokeMMO.exe com.pokeemu.client.Client
