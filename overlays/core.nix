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

  inherit (flakes.paseo.packages.${final.stdenv.hostPlatform.system}) paseo;
}
