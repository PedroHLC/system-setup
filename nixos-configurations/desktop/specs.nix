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
      sha256 = "65611d1e5e09c51fd4ef90f9da41f7000b41da8ab89ceaf2d89c499922f6f07f";
    };
  };
}
