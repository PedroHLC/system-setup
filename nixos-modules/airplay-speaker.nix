{ lib, config, ... }:
{
  services.shairport-sync = {
    enable = true;
    settings = {
      general = {
        output_backend = "pipewire";
        mdns_backend = "avahi";
      };
      pipewire = {
        sink_target = "alsa_output.pci-0000_04_00.6.analog-stereo";
        output_channels = 2;
      };
    };
  };

  # System-wide service doesn't work for me, but starting in my session does
  systemd.services.shairport-sync.wantedBy = lib.mkForce [ ];
  systemd.user.services.shairport-sync = {
    description = "shairport-sync";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    requires = [ "graphical-session.target" ];
    serviceConfig = {
      inherit (config.systemd.services.shairport-sync.serviceConfig) ExecStart;
      Slice = "session.slice";
      Restart = "on-failure";
      RestartSec = 5;
    };
    wantedBy = [ "graphical-session.target" ];
  };
}
