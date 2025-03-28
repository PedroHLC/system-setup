{ lib, ... }:

{
  options = {
    focusMode = lib.mkEnableOption "Whether to disable functionality to focus better.";
  };
  imports = [ ./focus-wide.nix ./focus-working.nix ];
  config = {
    specialisation.focus-mode.configuration = { ... }: {
      system.nixos.tags = [ "focus-mode" ];
      focusMode = true;
    };
  };
}
