# For the unique home-manager module
{
  cpuSensor = "k10temp-pci-00c3";
  dangerousAlone = false;
  dlnaName = "pedrohlc@xbox";
  gitKey = "F5BFC029DA9A28CE";
  gpuSensor = "amdgpu-pci-0400";
  nvmeSensors = [ "nvme-pci-0100" ];
  mainNetworkInterface = "enp2s0";
  seat = {
    displayId = "HDMI-A-2";
    displayWidth = 38400;
    displayHeight = 2160;
    displayRefresh = 60;
    displayBrightness = false;
    notificationX = "center";
    notificationY = "bottom";
    nvidiaPrime = false;
    touchpad = null;
    ctrlNearSpaceKeyMap = true;
  };
}
