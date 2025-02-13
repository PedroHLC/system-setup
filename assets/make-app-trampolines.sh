# Originally from https://github.com/craigfurman/nix-workstations/blob/fe7fa3da64425301a1f83f22475b6d3f20e6369d/home/apps/make-app-trampolines.sh

fromDir="$HOME/Applications/Home Manager Apps"
toDir="$HOME/Applications/Home Manager Trampolines"
mkdir -p "$toDir"

(
  cd "$fromDir"
  for app in *.app; do
    /usr/bin/osacompile -o "$toDir/$app" -e "do shell script \"open '$fromDir/$app'\""

    cp "$fromDir/$app/Contents/Resources"/*.icns "$toDir/$app/Contents/Resources/applet.icns"
  done
)

(
  cd "$toDir"
  for app in *.app; do
    if [ ! -d "$fromDir/$app" ]; then
      rm -rf "$toDir/$app"
    fi
  done
)
