# The top lambda and it super set of parameters.
{ config, pkgs, lib, ssot, ... }: with ssot;

# NixOS-defined options
let
  proxyAddr = "127.0.0.23";

  mkSystemdProxy = unitName: port: moduleInput: {
    systemd.sockets."proxy-${unitName}" = {
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = [
          "${vpn.desktop.v4}:${toString port}"
          "${vpn.desktop.v6}:${toString port}"
        ];
        NoDelay = true;
      };
    };

    systemd.services."proxy-${unitName}" = {
      requires = [ "${unitName}.service" "proxy-${unitName}.socket" ];
      after = [ "${unitName}.service" "proxy-${unitName}.socket" ];

      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${proxyAddr}:${toString port}";
        PrivateTmp = true;
      };
    };
  };
in
{
  # Network.
  networking = {
    hostId = "7116ddca";
    hostName = vpn.desktop.hostname;

    # Wireguard Client
    wireguard.interfaces.wg0 = {
      ips = [ "${vpn.desktop.v4}/${vpn.mask.v4}" "${vpn.desktop.v6}/${vpn.mask.v6}" ];
      privateKeyFile = "/var/persistent/secrets/wireguard-keys/private";
    };

    wireguard.interfaces.wg1.privateKeyFile = "/var/persistent/secrets/wgcf-teams/private";
  };

  # UPS monitoring
  power.ups = {
    enable = true;
    ups.sms-gamer = {
      driver = "sms_ser";
      description = "sms-gamer";
      port = "/dev/ttyUSB0";
    };

    users.first = {
      passwordFile = "/var/persistent/secrets/ups.psw";
      upsmon = "primary";
    };

    upsmon.monitor.sms-gamer = {
      user = "first";
    };
  };

  # DuckDNS
  chaotic.duckdns = {
    enable = true;
    domain = web.desktop.addr;
    environmentFile = "/var/persistent/secrets/duckdns.env";
  };

  # Better voltage, temperature, and a module to save me in case everything catches fire
  boot.extraModulePackages = with config.boot.kernelPackages; [
    zenpower
    (callPackage ../../packages/ksysrqd.nix { })
  ];
  boot.blacklistedKernelModules = [ "k10temp" ];

  # The service to start ksysrqd with my secret
  systemd.services.ksysrqd = {
    description = "Load ksysrqd module at boot";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "ksysrqd-ins" ''
        ${pkgs.kmod}/bin/modprobe ksysrqd password=$(cat /var/persistent/secrets/ksysrqd.psw)
      '';
      RemainAfterExit = true;
    };

    wantedBy = [ "multi-user.target" ];
  };

  boot.kernelParams = [
    # Let's use AMD P-State
    "amd-pstate=guided"
  ];

  # GPU
  environment.variables.RADV_PERFTEST = "sam,video_decode,transfer_queue";

  # Loads GPU earlier in boot
  boot.initrd.availableKernelModules = [ "amdgpu" ];

  # Up-to 192kHz in the Focusrite
  services.pipewire.extraConfig.pipewire."99-playback-96khz" = {
    "context.properties" = {
      "default.clock.rate" = 96000;
      "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
    };
  };

  # Up-to 192kHz in the Focusrite (thanks to https://another.maple4ever.net/archives/2994/)
  # and virtualization MSRS
  boot.extraModprobeConfig = ''
    options snd_usb_audio vid=0x1235 pid=0x8211 device_setup=1 quirk_flags=0x1
    options kvm ignore_msrs=1
  '';


  # B550I AORUS PRO AX issue with suspension
  systemd.services.fix-b550i-acpi-wakeup = {
    description = "Disable misbehaving device from waking-up computer from sleep.";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo GPP0 > /proc/acpi/wakeup
    '';
  };

  # Gaming mouse stuff
  services.ratbagd.enable = true;

  # Limit resources used by nix-daemon.
  systemd.services.nix-daemon.serviceConfig.AllowedCPUs = "2-23";

  # Extra packages
  environment.systemPackages = with pkgs; [
    (cfwarp-add.override { substitutions = { "192.168.0.1" = "192.168.18.1"; }; })
    i2pd
    latencyflex-vulkan
    nixos-next-shot
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
    uxplay
    virtiofsd # for libvirtd
    vkbasalt
  ];

  # AI (Ollama)
  services.ollama = {
    enable = true;
    host = proxyAddr;
    port = vpn.desktop.ollamaPort;
    acceleration = "rocm";
    loadModels = [ "gpt-oss:20b" ];
    user = "ollama";
    group = "agents";
    package =
      if pkgs.ollama.version == "0.11.4" then
      # For OLLAMA_NEW_ESTIMATES
        pkgs.ollama-rocm.overrideAttrs
          (_prevAttrs: {
            src = pkgs.fetchFromGitHub {
              owner = "ollama";
              repo = "ollama";
              tag = "v0.11.5-rc2";
              hash = "sha256-/uo35G5aWyU/TBPeaCA1muw2hZgOokONW29Ox9vZgg4=";
            };
          })
      else throw "New ollama found!";
    environmentVariables = {
      HCC_AMDGPU_TARGET = "gfx1030"; # not really needed
      OLLAMA_NEW_ESTIMATES = "1";
    };
  };
  chaotic.mesa-git.extraPackages = with pkgs; [ rocmPackages.clr.icd ];
  systemd.services.ollama = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      RestrictNamespaces = lib.mkForce false;
    };
    wantedBy = lib.mkForce [ ];
  };

  # AI (ollama chat)
  services.nextjs-ollama-llm-ui = {
    enable = true;
    hostname = proxyAddr;
    port = vpn.desktop.nextjsOllamaPort;
    ollamaUrl = "http://${vpn.desktop.v4}:${toString vpn.desktop.ollamaPort}";
  };
  systemd.services.nextjs-ollama-llm-ui.wantedBy = lib.mkForce [ ];

  # AI (llama.cpp)
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-vulkan;
    host = proxyAddr;
    port = vpn.desktop.llamaCppPort;
    model = "${config.users.users.llama-cpp.home}/models/ggml-gpt-oss-20b.gguf";
    extraFlags = [ "-c" "0" "-fa" "--jinja" ];
  };
  users.users.llama-cpp = {
    home = "/var/lib/llama-cpp";
    isSystemUser = true;
    inherit (config.services.ollama) group;
  };
  systemd.services.llama-cpp = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      RestrictNamespaces = lib.mkForce false;
      User = "llama-cpp";
      Group = config.services.ollama.group;
      WorkingDirectory = config.users.users.llama-cpp.home;
      StateDirectory = [ "llama-cpp" ];
    };
    wantedBy = lib.mkForce [ ];
  };

  # AI (systemd activation sockets)
  imports =
    [
      (mkSystemdProxy "ollama" vpn.desktop.ollamaPort)
      (mkSystemdProxy "nextjs-ollama-llm-ui" vpn.desktop.nextjsOllamaPort)
      (mkSystemdProxy "llama-cpp" vpn.desktop.llamaCppPort)
    ];

  # One-button virtualization for some tests of mine
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };
  users.extraUsers.pedrohlc.extraGroups = [ "libvirtd" ];

  # Not important but persistent files
  environment.persistence = {
    "/var/persistent" = {
      users.pedrohlc.directories = [
        ".config/OpenRCT2"
        ".local/share/diasurgical"
        ".local/share/vcmi"
      ];
    };
    "/var/residues" = {
      users.pedrohlc.directories = [
        ".cache/vcmi"
        ".config/vcmi"
        ".config/VCMI Team"
      ];
      directories = [
        "/var/lib/nut"
        "/var/lib/libvirt"
        "/var/lib/llama-cpp"
        "/var/lib/ollama"
      ];
    };
  };

  # Feature set
  nix.settings.system-features = [
    # Allows building v4 packages
    "big-parallel"
    "gccarch-x86-64-v3"
    # Allows building Nixpkgs tests
    "kvm"
    "nixos-test"
  ];

  # Allows HDR gaming (AMD-GPU only).
  chaotic.hdr = {
    enable = true;
    specialisation.enable = false;
    wsiPackage = pkgs.gamescope-wsi_git;
  };

  # Allows streaming with KMS
  security.wrappers.sunshine = {
    source = "${pkgs.sunshine}/bin/sunshine";
    capabilities = "cap_sys_admin+pie";
    owner = "root";
    group = "root";
  };

  # Emulates macbook keyboard mapping
  services.udev.extraHwdb = ''
    evdev:input:b0003v0C45p767E*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_700E0=key_leftmeta
      KEYBOARD_KEY_700E3=key_leftalt
      KEYBOARD_KEY_700E2=key_leftctrl
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "23.11"; # Did you read the comment?
}
