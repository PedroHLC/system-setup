# For the unique home-manager module
{
  cpuSensor = "k10temp-pci-00c3";
  dangerousAlone = false;
  dlnaName = "pedrohlc@desktop";
  gitKey = "DF4C6898CBDC6DF5";
  gpuSensor = "amdgpu-pci-0900";
  nvmeSensors = [ "nvme-pci-0100" "nvme-pci-0400" ];
  ups = "sms-gamer";
  seat = {
    autoLogin = false; # disable .profile auto-starting DE
    displayId = "DP-1";
    displayWidth = 3840;
    displayHeight = 2160;
    displayRefresh = 60;
    displayBrightness = false;
    displayInputSource = "0x0f";
    notificationX = "center";
    notificationY = "bottom";
    nvidiaPrime = false;
    touchpad = null;
    sunshine = true;
    ctrlNearSpaceKeyMap = true;
  };
}
