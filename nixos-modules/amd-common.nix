{
  boot.kernelParams = [
    "amdgpu.gpu_recovery=1"
    "amdgpu.lockup_timeout=5000"
    "amdgpu.runpm=0"
    # Let's use AMD P-State
    "amd-pstate=active"
  ];

  # Enable all experimental
  environment.variables.RADV_EXPERIMENTAL = "heap,hic,transfer_queue";

  # Loads GPU earlier in boot
  boot.initrd.availableKernelModules = [ "amdgpu" ];

  # Feature set
  nix.settings.system-features = [
    # Allows building v4 packages
    "big-parallel"
    "gccarch-x86-64-v3"
    # Allows building Nixpkgs tests
    "kvm"
    "nixos-test"
  ];
}
