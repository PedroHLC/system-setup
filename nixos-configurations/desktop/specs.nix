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
    ctrlNearSpaceKeyMap = true;
    steamMachine = {
      output = "HDMI-A-1";
      salt = "pedrohlc";
      sha256 = "ede8637cc02db75bd5af3f5df40b87bd1677b8bf48effaa2ade5e9db37274c28";
    };
  };
}
