{ pkgs, ... }:

let
  ddcutil = dest: "${pkgs.ddcutil}/bin/ddcutil setvcp 60 ${dest} --noverify";
  toLinux = ddcutil "0x0f"; # DP-1
  toOther = ddcutil "0x06"; # HDMI-2
in {
  # Hardware setup
  hardware.i2c.enable = true;

  # Service: Switch TO Linux
  systemd.services.monitor-to-linux = {
    description = "Monitor Switch: Pull to Linux (DP-1)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = toLinux;
      User = "pedrohlc";
    };
  };

  # Service: Switch AWAY from Linux
  systemd.services.monitor-to-other = {
    description = "Monitor Switch: Push to Other (HDMI-2)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = toOther;
      User = "pedrohlc";
    };
  };

  # 2. The udev Rule "Both Ways"
  services.udev.extraRules = ''
    # When Ugreen Hub ARRIVES: Switch monitor to this PC (DP-1)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="monitor-to-linux.service"

    # When Ugreen Hub LEAVES: Switch monitor to the other PC (HDMI-2)
    ACTION=="unbind", SUBSYSTEM=="usb", ENV{PRODUCT}=="5e3/610/663", \
        TAG+="systemd", ENV{SYSTEMD_WANTS}+="monitor-to-other.service"
  '';
}
