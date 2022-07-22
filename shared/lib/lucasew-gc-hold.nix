# Adapted from https://github.com/lucasew/nixcfg/blob/e713568627ad37c0bf508edcb63de444237e6afc/modules/hold-gc/system.nix
{ config, pkgs, lib, self, ... }: {
  options.lucasew = with lib; {
    gc-hold = mkOption {
      description = "Paths to hold for GC";
      type = types.listOf types.package;
      default = [ ];
    };
  };
  config =
    let
      getPath = drv: drv.outPath;
      flakePaths = lib.attrValues self.inputs;
      allDrvs = config.lucasew.gc-hold ++ flakePaths;
      paths = map (getPath) allDrvs;
      pathsStr = lib.concatStringsSep "\n" paths;
    in
    {
      environment.etc.nix-gchold.text = pathsStr;
    };
}
