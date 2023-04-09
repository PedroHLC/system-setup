{ writeShellScriptBin, alsaLib, jdk17, gamemode }:
# This game seems to embed the openal library inside its "executable",
# and it does not support pipewire. So I preloaded the alsa backend for it.
writeShellScriptBin "pokemmo" ''
  cd ~/Games/PokeMMO

  exec ${gamemode}/bin/gamemoderun \
    LD_PRELOAD="${alsaLib}/lib/libasound.so.2" ALSOFT_DRIVERS="alsa" \
    ${jdk17}/bin/java -Dfile.encoding="UTF-8" -cp PokeMMO.exe com.pokeemu.client.Client
''
