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

        # Latest vulkan-sdk (waiting for https://nixpk.gs/pr-tracker.html?pr=187918)
        glslang = prev.glslang.overrideAttrs (oldAttrs: rec {
          version = "1.3.224.1";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "glslang";
            rev = "sdk-${version}";
            hash = "sha256-VEOENuy/VhYBBX52O4QHJFXUjsj6jL4vDD4cLDlQcIA=";
          };
        });
        spirv-headers = prev.spirv-headers.overrideAttrs (oldAttrs: {
          version = "1.3.224.1";
        });
        vulkan-headers = prev.vulkan-headers.overrideAttrs (oldAttrs: rec {
          version = "1.3.227";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "Vulkan-Headers";
            rev = "v${version}";
            hash = "sha256-eZ53a1XhDpdr1hMRITdR8ZZmefbfqXhx1EywfDPPsjI=";
          };
        });
        vulkan-loader = prev.vulkan-loader.overrideAttrs (oldAttrs: rec {
          version = "1.3.227";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "Vulkan-Loader";
            rev = "v${version}";
            hash = "sha256-iBIjIbqbxakTSWLU+2jKTy7pNt6rq7cTAx67gNtOE1M=";
          };
        });
        spirv-tools = prev.spirv-tools.overrideAttrs (oldAttrs: rec {
          version = "2022.3";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "SPIRV-Tools";
            rev = "v${version}";
            hash = "sha256-B1FOZ6Q8HEgmuin2yvw2uFJy6B5NHkUHrLSlJmTH/kk=";
          };
        });
        vulkan-extension-layers = prev.vulkan-extension-layers.overrideAttrs (oldAttrs: rec {
          version = "1.3.225";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "Vulkan-ExtensionLayer";
            rev = "v${version}";
            hash = "sha256-555wtfuAYWzUFtf0NOJCNzWW+/ogRUgkaWw8NdW2vb8=";
          };
        });
        vulkan-tools = prev.vulkan-tools.overrideAttrs (oldAttrs: rec {
          version = "1.3.227";
          src = final.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "Vulkan-Tools";
            rev = "v${version}";
            hash = "sha256-i7DtuXmrSjj9BfWA33mYJS9WiQXRa3pl3Jhq69ZNvFQ=";
          };
        });
      };
    in
    [ thisConfigsOverlay ];

  # Apply latest mesa in the system
  hardware.opengl.package = pkgs.mesa-bleeding;
  hardware.opengl.package32 = pkgs.lib32-mesa-bleeding;
}
