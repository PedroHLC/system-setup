final: prev: {
  # Bring GSP and related GPU stuff, but without any other GPU
  makeModulesClosure = args: (prev.makeModulesClosure args).overrideAttrs (prevAttrs: {
    builder = final.writeShellScript "modules-closure.sh" ((builtins.readFile prevAttrs.builder) + ''
      mv "$out/lib/firmware/nvidia" "$out/lib/firmware/_nvidia"
      mkdir "$out/lib/firmware/nvidia"
      mv "$out/lib/firmware/_nvidia/ga10"{2,7} "$out/lib/firmware/nvidia/"
      rm -rf "$out/lib/firmware/_nvidia"
    '');
  });

  # Allow steam to find nvidia-offload script
  steam = prev.steam.override {
    extraPkgs = _: [ final.nvidia-offload ];
  };

  # NVIDIA Offloading (ajusted to work on Wayland and XWayland).
  nvidia-offload = final.callPackage ../packages/scripts { scriptName = "nvidia-offload"; };
}
