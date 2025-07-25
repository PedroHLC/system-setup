# Adapted from: https://github.com/dseum/nix-config/blob/2e8a3045f8c56fa6ba2657432494cd27fc7999c7/module/darwin/home-manager.nix#L28
{ config, pkgs, lib, ... }:

{
  targets.darwin.linkApps.enable = false;

  home = {
    activation.linkApps = lib.hm.dag.entryAfter [ "installPackages" ] (
      let
        applications = pkgs.buildEnv {
          name = "user-applications";
          paths = config.home.packages;
          pathsToLink = "/Applications";
        };
      in
      ''
        set -e

        targetFolder=${lib.strings.escapeShellArg config.targets.darwin.linkApps.directory}

        echo "setting up ~/$targetFolder..." >&2

        ourLink () {
          local link
          link=$(readlink "$1")
          [ -L "$1" ] && [ "''${link#*-}" = "home-manager-files/$targetFolder" ]
        }

        if [ -e "$targetFolder" ] && ourLink "$targetFolder"; then
          rm "$targetFolder"
        fi

        mkdir -p "$targetFolder"

        rsyncFlags=(
          --archive
          --checksum
          --copy-unsafe-links
          --delete
          --exclude=$'Icon\r'
          --no-group
          --no-owner
        )

        ${lib.getExe pkgs.rsync} "''${rsyncFlags[@]}" ${applications}/Applications/ "$targetFolder"
      ''
    );
  };
}
