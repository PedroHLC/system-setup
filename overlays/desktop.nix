flakes: final: prev: {
  cecd = final.callPackage "${flakes.jovian}/pkgs/cecd/default.nix" { };
  inputattach-cec-units = final.callPackage "${flakes.jovian}/pkgs/inputattach-cec-units/default.nix" { };
}
