{ lib, ... }:

{
  options = {
    focusMode = lib.mkEnableOption "Whether to disable functionality to focus better.";
  };
  imports = [ ./configs/focus-wide.nix ./configs/focus-working.nix ];
  config = {
    specialisation.focus-mode.configuration = { ... }: {
      system.nixos.tags = [ "focus-mode" ];
      focusMode = true;
    };
  };
}
