{
  boot.kernelParams = [
    "amdgpu.gpu_recovery=1"
    "amdgpu.lockup_timeout=5000"
    "amdgpu.runpm=0"
  ];

  # Enable all experimental
  environment.variables.RADV_EXPERIMENTAL = "heap,hic,transfer_queue";

  # Loads GPU earlier in boot
  boot.initrd.availableKernelModules = [ "amdgpu" ];
}
