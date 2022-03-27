# The top lambda and it super set of parameters.
{ nix-gaming, config, lib, pkgs, ... }:

# NixOS-defined options
{
  # Network.
  networking = {
    hostId = "7116ddca";
    hostName = "desktop";
  };

  # Services/Programs configurations
  services.minidlna.friendlyName = "desktop";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

