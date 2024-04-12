{ lib, ... }:

{
  options = {
    focusMode = lib.mkEnableOption "Whether to disable functionality to focus better.";
  };
  imports = [ ../config/focus-wide.nix ../config/focus-working.nix ];
  config = {
    specialisation.focus-mode.configuration = { ... }: {
      system.nixos.tags = [ "focus-mode" ];
      focusMode = true;
    };
  };
}
