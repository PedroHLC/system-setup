utils: with utils;

# My simple and humble bar
let
  interval = 4;
in
{
  programs.i3status-rust = {
    enable = hasLinuxSeat;
    bars = {
      main = {
        settings = {
          theme.theme = "solarized-dark";
          icons.icons = "awesome5";
        };
        blocks = with bin; [
          {
            block = "custom";
            command = ''echo -n ' '; ${swayncClient} -c; [ "x$(${swayncClient} -D)" = 'xtrue' ] && echo " (DND)"'';
            inherit interval;
          }
          {
            block = "custom";
            command = "echo -n ' '; ${who} | ${grep} 'pts/' | ${wc} -l | ${tr} '\\n' '/'; ${who} | ${wc} -l";
            inherit interval;
          }
          {
            block = "toggle";
            format = " $icon";
            command_state = "${systemctl} is-active -q sshd && echo a";
            command_on = "${sudo} ${systemctl} start sshd";
            command_off = "${sudo} ${systemctl} stop sshd";
            inherit interval;
          }
          {
            block = "toggle";
            format = " $icon";
            command_state = "${bluetoothctl} show | ${grep} 'Powered: yes'";
            command_on = "${sudo} ${pkgs.util-linux}/bin/rfkill unblock bluetooth && ${sudo} ${systemctl} start bluetooth && ${bluetoothctl} --timeout 4 power on";
            command_off = "${bluetoothctl} --timeout 4 power off; ${sudo} ${systemctl} stop bluetooth && ${sudo} ${pkgs.util-linux}/bin/rfkill block bluetooth";
            inherit interval;
          }
          {
            block = "toggle";
            format = " $icon";
            command_state = "${nmcli} r wifi | ${grep} '^d'";
            command_on = "${nmcli} r wifi off";
            command_off = "${nmcli} r wifi on";
            inherit interval;
          }
          {
            block = "net";
            device = "wlan0";
            format = "$icon $ssid ($signal_strength)";
            missing_format = "";
            inherit interval;
          }
          {
            block = "net";
            device = mainNetworkInterface;
            format = "^icon_net_down $speed_down.eng(prefix:K) ^icon_net_up $speed_up.eng(prefix:K)";
            missing_format = "";
            inherit interval;
          }
          {
            block = "disk_space";
            path = "/";
            format = "$icon $available";
            interval = 20;
            warning = 20.0;
            alert = 10.0;
          }
          {
            block = "memory";
            format = "$icon $mem_used_percents";
            inherit interval;
          }
          {
            block = "cpu";
            interval = interval / 2;
          }
        ] ++ (lists.optional (cpuSensor != null)
          {
            block = "temperature";
            format = "$icon $average";
            chip = cpuSensor;
            inherit interval;
          }
        ) ++ (lists.optional (gpuSensor != null)
          {
            block = "temperature";
            format = "$icon $average";
            chip = gpuSensor;
            inherit interval;
          }
        ) ++ (map
          (sensor: {
            block = "temperature";
            format = "$icon $max";
            chip = sensor;
            inherit interval;
            idle = 37;
            info = 49;
            warning = 60;
          })
          nvmeSensors
        ) ++ [
          {
            block = "sound";
          }
        ] ++ (lists.optional hasBattery
          {
            block = "battery";
            inherit interval;
            device = battery;
          }
        ) ++ (lists.optional hasUPS
          {
            block = "custom";
            command = "echo -n ' '; ${pkgs.nut}/bin/upsc ${ups} 'ups.load' | ${sed} s/\\.00/%/";
            inherit interval;
          }
        ) ++ [{
          block = "custom";
          command =
            let
              localDay = "${date} +'%d/%m'";
              brTime = "TZ='America/Sao_Paulo' ${date} +'BR{%H:%M}'";
              ukTime = "TZ='Europe/London' ${date} +'UK{%H:%M}'";
            in
            "(${localDay}; ${brTime}; ${ukTime}) | ${tr} '\\n' ' '";
          interval = interval * 2;
        }];
      };
    };
  };
}
