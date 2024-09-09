{ final, prev }:
prev.zoom-us.overrideAttrs (oa: {
  nativeBuildInputs = oa.nativeBuildInputs ++ [ final.bbe ];
  postFixup =
    let
      anchorPattern = "--prefix LD_LIBRARY_PATH \":\" ";
      addPwV4l2 = "--prefix LD_PRELOAD : '${final.pipewire.out}/lib/pipewire-0.3/v4l2/libpw-v4l2.so'";
      fakeGnome = "--set XDG_CURRENT_DESKTOP gnome";

      mainWrapperTweakedFixup =
        builtins.replaceStrings
          [
            anchorPattern
            "libpulseaudio-17.0/lib"
            "--prefix PATH : "
            "/bin \\"
          ]
          [
            "${addPwV4l2} ${fakeGnome} ${anchorPattern} \${APP_LIBS="
            "libpulseaudio-17.0/lib}"
            "--prefix PATH : \${APP_PATH="
            "/bin} \\"
          ]
          oa.postFixup;
    in
    mainWrapperTweakedFixup + ''
      cp $out/opt/zoom/zoom zoom.bak
      bbe -e 's/\0manjaro\0/\0nixos\0\0\0/' < zoom.bak > $out/opt/zoom/zoom

      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/opt/zoom/ZoomWebviewHost
      wrapProgram $out/opt/zoom/ZoomWebviewHost \
         --chdir "$out/opt/zoom" \
         --prefix PATH : "$APP_PATH" \
         --prefix LD_LIBRARY_PATH : "$APP_LIBS:$out/opt/zoom/cef:$out/opt/zoom/Qt/lib"
    '';
})
