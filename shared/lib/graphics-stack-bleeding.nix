{ pkgs, mesa-git-src, ... }:
{
  nixpkgs.overlays =
    let
      galliumDrivers = [ "auto" "zink" "virgl" ];
      vulkanDrivers = [ "auto" "virtio-experimental" ];

      thisConfigsOverlay = final: prev: {

        # Latest mesa with more drivers
        mesa-bleeding = (final.callPackage ../pkgs/mesa {
          llvmPackages = final.llvmPackages_latest;
          inherit (final.darwin.apple_sdk.frameworks) OpenGL;
          inherit (final.darwin.apple_sdk.libs) Xplugin;
          inherit galliumDrivers vulkanDrivers;
          inherit mesa-git-src;
        }).drivers;
        lib32-mesa-bleeding = (final.pkgsi686Linux.callPackage ../pkgs/mesa {
          llvmPackages = final.pkgsi686Linux.llvmPackages_latest;
          inherit (final.pkgsi686Linux.darwin.apple_sdk.frameworks) OpenGL;
          inherit (final.pkgsi686Linux.darwin.apple_sdk.libs) Xplugin;
          inherit galliumDrivers vulkanDrivers;
          inherit mesa-git-src;
        }).drivers;
      };
    in
    [ thisConfigsOverlay ];

  # Apply latest mesa in the system
  hardware.opengl.package = pkgs.mesa-bleeding;
  hardware.opengl.package32 = pkgs.lib32-mesa-bleeding;
}
