{ lib, fetchFromGitHub, linuxPackagesFor, linuxKernel, linux_6_0 ? linuxKernel.kernels.linux_6_0, ... }:
let
  version = "6.0.13";
  suffix = "lqx3";
  sha256 = "0dc295d9dfm3j2nmvkzy21ky1k6jp7c7miqjhqgfjny9yk1b41k4";
in
# hopefully matches j35rm1y41m309qry0gp48kbwjhp662g6 from cache.nixos.org (right now it does)
linuxPackagesFor (linux_6_0.override {
  argsOverride = rec {
    inherit version;
    modDirVersion = lib.versions.pad 3 "${version}-${suffix}";
    isZen = true;
    src = fetchFromGitHub {
      owner = "zen-kernel";
      repo = "zen-kernel";
      rev = "v${version}-${suffix}";
      inherit sha256;
    };
  };
})
