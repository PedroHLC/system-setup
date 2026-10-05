{
  boot.kernelParams = [
    # Let's use AMD P-State
    "amd-pstate=active"
  ];

  # Feature set
  nix.settings.system-features = [
    "gccarch-x86-64-v2"
    "gccarch-x86-64-v3"
  ];
}
