{ writeShellScriptBin
, writeShellScript
, fish
, nixpkgs-review
, libnotify
, tmux
, nixpkgs ? "$HOME/Projects/com.pedrohlc/nixpkgs"
, gitHubSecrets ? "$HOME/.secrets/github.nixpkgs-review.env"
}:
let
  finishShell = writeShellScript "nrpr-notify-and-shell" ''
    ${libnotify}/bin/notify-send "$(basename $PWD) finished building"
    exec ${fish}/bin/fish
  '';

  interShell = writeShellScript "nrpr-inside" ''
    cd "${nixpkgs}"
    export NIXPKGS_ALLOW_UNFREE=1
    source "${gitHubSecrets}"
    ${nixpkgs-review}/bin/nixpkgs-review pr --run "${finishShell}" "$@"
    echo "Exited with code " "$?"
    read
  '';

  outerShell =
    writeShellScriptBin "nrpr" ''
      ${tmux}/bin/tmux new-session ${interShell} "$@"
    '';
in
outerShell
