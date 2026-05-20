{
  boot.kernelParams = [
    # Let's use AMD P-State
    "amd-pstate=active"
  ];

  # Feature set
  nix.settings.system-features = [
    # Allows building v3 packages
    "big-parallel"
    "gccarch-x86-64-v3"
    # Allows building Nixpkgs tests
    "kvm"
    "nixos-test"
  ];
}
