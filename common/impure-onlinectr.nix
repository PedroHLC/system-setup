let
  nixpkgsFlake = builtins.getFlake "nixpkgs";
  system = builtins.currentSystem;
  pkgs = nixpkgsFlake.legacyPackages.${system};
  src = builtins.fetchTarball "https://github.com/OnlineCTR/server/archive/refs/heads/stable.tar.gz";
  callPackage =
    if system == "aarch64-linux" then
      pkgs.pkgsCross.armv7l-hf-multiplatform.callPackage
    else if system == "x86_64-linux" then
      pkgs.pkgsi686Linux.callPackage
    else
      throw "Unrecognized system";

in
callPackage src { }
