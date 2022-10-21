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

        vkBasalt = prev.vkBasalt.overrideAttrs (_: rec {
          version = "0.3.2.6";
          src = final.fetchFromGitHub {
            owner = "DadSchoorse";
            repo = "vkBasalt";
            rev = "v${version}";
            hash = "sha256-wk/bmbwdE1sBZPlD+EqXfQWDITIfCelTpoFBtNtZV8Q=";
          };
        });

        # Latest vulkan-sdk (waiting for https://nixpk.gs/pr-tracker.html?pr=189290)
        # glslang = prev.glslang.overrideAttrs (_: rec {
        #   version = "1.3.224.1";
        #   src = final.fetchFromGitHub {
        #     owner = "KhronosGroup";
        #     repo = "glslang";
        #     rev = "sdk-${version}";
        #     hash = "sha256-VEOENuy/VhYBBX52O4QHJFXUjsj6jL4vDD4cLDlQcIA=";
        #   };
        # });
        # vulkan-headers = prev.vulkan-headers.overrideAttrs (_: rec {
        #   version = "1.3.230";
        #   src = final.fetchFromGitHub {
        #     owner = "KhronosGroup";
        #     repo = "Vulkan-Headers";
        #     rev = "v${version}";
        #     hash = "sha256-lIe8zd0iUjPS0k2qjO1Zrl1Gbtty9uluCzHkWeVqv0A=";
        #   };
        # });
        # vulkan-loader = prev.vulkan-loader.overrideAttrs (_: rec {
        #   version = "1.3.230";
        #   src = final.fetchFromGitHub {
        #     owner = "KhronosGroup";
        #     repo = "Vulkan-Loader";
        #     rev = "v${version}";
        #     hash = "sha256-KO6RRv1SibaCA2ZVDcV/0KR8+YJ6kJQurdQtjqWFxjM=";
        #   };
        # });
        # spirv-tools = prev.spirv-tools.overrideAttrs (_: rec {
        #   version = "2022.3";
        #   src = final.fetchFromGitHub {
        #     owner = "KhronosGroup";
        #     repo = "SPIRV-Tools";
        #     rev = "v${version}";
        #     hash = "sha256-B1FOZ6Q8HEgmuin2yvw2uFJy6B5NHkUHrLSlJmTH/kk=";
        #   };
        # });
        # vulkan-tools = prev.vulkan-tools.overrideAttrs (_: rec {
        #   version = "1.3.230";
        #   src = final.fetchFromGitHub {
        #     owner = "KhronosGroup";
        #     repo = "Vulkan-Tools";
        #     rev = "v${version}";
        #     hash = "sha256-eWT/ADApEUJYHWmRQp86lo1bOjr0tTPQJakfJWeClOw=";
        #   };
        # });
      };
    in
    [ thisConfigsOverlay ];

  # Apply latest mesa in the system
  hardware.opengl.package = pkgs.mesa-bleeding;
  hardware.opengl.package32 = pkgs.lib32-mesa-bleeding;
}
