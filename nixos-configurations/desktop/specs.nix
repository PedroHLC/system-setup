# For the unique home-manager module
{
  cpuSensor = "zenpower-pci-00c3";
  dangerousAlone = false;
  dlnaName = "pedrohlc@desktop";
  gitKey = "DF4C6898CBDC6DF5";
  gpuSensor = "amdgpu-pci-0900";
  nvmeSensors = [ "nvme-pci-0100" "nvme-pci-0400" ];
  ups = "sms-gamer";
  seat = {
    displayId = "DP-1";
    displayWidth = 3840;
    displayHeight = 2160;
    displayRefresh = 60;
    displayBrightness = false;
    notificationX = "center";
    notificationY = "bottom";
    nvidiaPrime = false;
    touchpad = null;
    sunshine = true;
    kvm = { left = "laptop"; right = "foreign"; };
    emulateMacKeyMap = true;
    steamMachine = {
      output = "card0-HDMI-A-1";
      salt = "pedrohlc";
      sha256 = "8cb5ac55e797e8de225b69020248932d2c9f4317b41f2d4048fc4e04fa77e597";
    };
  };
}
