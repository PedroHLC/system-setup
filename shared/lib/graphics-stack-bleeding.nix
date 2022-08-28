{ pkgs, ... }:
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
        }).drivers;
        lib32-mesa-bleeding = (final.pkgsi686Linux.callPackage ../pkgs/mesa {
          llvmPackages = final.pkgsi686Linux.llvmPackages_latest;
          inherit (final.pkgsi686Linux.darwin.apple_sdk.frameworks) OpenGL;
          inherit (final.pkgsi686Linux.darwin.apple_sdk.libs) Xplugin;
          inherit galliumDrivers vulkanDrivers;
        }).drivers;

        # Latest vulkan-sdk (waiting for https://nixpk.gs/pr-tracker.html?pr=187918)
        glslang = prev.glslang.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.0";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "glslang";
            rev = "sdk-${version}";
            hash = "sha256-+NKp/4e3iruAcTunpxksvCHxoVYmPd0kFI8JDJJUVg4=";
          };
        });
        spirv-headers = prev.spirv-headers.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.0";
        });
        vulkan-headers = prev.vulkan-headers.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.0";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "Vulkan-Headers";
            rev = "sdk-${version}";
            hash = "sha256-zUT5+Ttmkrj51a9FS1tQxoYMS0Y0xV8uaCEJNur4khc=";
          };
        });
        vulkan-loader = prev.vulkan-loader.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.0";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "Vulkan-Loader";
            rev = "sdk-${version}";
            hash = "sha256-lmdImPeosHbAbEzPVW4K9Wkz/mF6gr8MVroGf0bDEPc=";
          };
        });
        spirv-tools = prev.spirv-tools.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.0";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "SPIRV-Tools";
            rev = "sdk-${version}";
            hash = "sha256-jpVvjrNrTAKUY4sjUT/gCUElLtW4BrznH1DbStojGB8=";
          };
        });
        vulkan-validation-layers = prev.vulkan-validation-layers.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.0";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "Vulkan-ValidationLayers";
            rev = "sdk-${version}";
            hash = "sha256-MmAxUuV9CVJ6LHUb6ePEiE37meDB1TqPAwLsPdHQ1u8=";
          };
        });
        vulkan-extension-layers = prev.vulkan-extension-layers.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.0";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "Vulkan-ExtensionLayer";
            rev = "sdk-${version}";
            hash = "sha256-KOlwtfuAYWzUFtf0NOJCNzWW+/ogRUgkaWw8NdW2vb8=";
          };
        });
        vulkan-tools-lunarg = prev.vulkan-tools-lunarg.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.0";
          src = final.fetchFromGitHub {
            owner = "LunarG";
            repo = "VulkanTools";
            rev = "sdk-${version}";
            hash = "sha256-YQv6YboyQJjLTEKspZQdV8YFhHux/4RIncHXOsz1cBw=";
            fetchSubmodules = true;
          };
        });
        vulkan-tools = prev.vulkan-tools.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.0";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "Vulkan-Tools";
            rev = "sdk-${version}";
            hash = "sha256-Z+QJBd2LBdiJD1fHhBLbOfOoLhqTg0J3tq+XQRSiQaY=";
          };
        });
      };
    in
    [ thisConfigsOverlay ];

  # Apply latest mesa in the system
  hardware.opengl.package = pkgs.mesa-bleeding;
  hardware.opengl.package32 = pkgs.lib32-mesa-bleeding;
}
