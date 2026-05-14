{ lib, pkgs, ... }:
{
  # For development, but disabled to start service on-demand
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql; # always the latest
    settings = {
      # log_statement = "all";
      # logging_collector = true;
      log_destination = lib.mkForce "syslog";
    };
  };
  systemd.services.postgresql.wantedBy = lib.mkForce [ ]; # don't start with system
}
