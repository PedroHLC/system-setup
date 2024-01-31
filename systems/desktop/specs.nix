# For the unique home-manager module
{
  cpuSensor = "zenpower-pci-00c3";
  dangerousAlone = false;
  dlnaName = "pedrohlc@desktop";
  gitKey = "DF4C6898CBDC6DF5";
  gpuSensor = "amdgpu-pci-0900";
  nvmeSensors = [ "nvme-pci-0100" "nvme-pci-0400" ];
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
  };
}
