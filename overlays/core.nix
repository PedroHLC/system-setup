flakes: final: _prev: {
  nixos-clear = final.callPackage ../packages/scripts { scriptName = "nixos-clear"; };
  nixos-next-shot = final.callPackage ../packages/scripts {
    scriptName = "nixos-next-shot";
    substitutions = {
      "$(which bootctl)" = "${final.systemd}/bin/bootctl";
      "$(which systemctl)" = "${final.systemd}/bin/systemctl";
    };
  };

  aria2c-for-wget-curl = final.callPackage ../packages/aria2c-for-wget-curl.nix { };

  claude-code = final.callPackage "${flakes.latest-claude-code}/package.nix" { };

  paseo = flakes.paseo.packages.${final.stdenv.hostPlatform.system}.paseo.overrideAttrs (oa: {
    # easier to find
    installPhase =
      builtins.replaceStrings
        [ "makeWrapper" "$out/bin/paseo-server " "$out/bin/paseo " ]
        [
          "makeBinaryWrapper"
          "$out/bin/paseo-server --inherit-argv0 "
          "$out/bin/paseo --inherit-argv0 "
        ]
        oa.installPhase;
    nativeBuildInputs = oa.nativeBuildInputs ++ [ final.makeBinaryWrapper ];
    # fixes paseo#3249
    postInstall = (oa.postInstall or "") + ''
      cp -r packages/server/node_modules/node-pty/prebuilds "$out/lib/paseo/packages/server/node_modules/node-pty/"
    '';
  });
}
