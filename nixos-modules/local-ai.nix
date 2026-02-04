{ pkgs, ssot, lib, ... }@args: with ssot;

let
  proxyAddr = "127.0.0.23";

  mkSystemdProxy = import ../common/mk-systemd-proxy.nix proxyAddr args;
in
{
  # AI (Ollama)
  services.ollama = {
    enable = true;
    host = proxyAddr;
    port = machines.desktop.vpn.ollamaPort;
    acceleration = "rocm";
    loadModels = [ "gpt-oss:20b" ];
    user = "ollama";
    group = "agents";
    environmentVariables = {
      HCC_AMDGPU_TARGET = "gfx1030"; # not really needed
      OLLAMA_NEW_ENGINE = "1"; # not really needed for this model
      OLLAMA_NEW_ESTIMATES = "1";
      OLLAMA_KV_CACHE_TYPE = "q4_0";
      OLLAMA_FLASH_ATTENTION = "1";
    };
  };
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
    port = machines.desktop.vpn.nextjsOllamaPort;
    ollamaUrl = "http://${machines.desktop.vpn.v4}:${toString machines.desktop.vpn.ollamaPort}";
  };
  systemd.services.nextjs-ollama-llm-ui.wantedBy = lib.mkForce [ ];

  # AI (systemd activation sockets)
  imports =
    [
      (mkSystemdProxy "ollama" machines.desktop.vpn.ollamaPort)
      (mkSystemdProxy "nextjs-ollama-llm-ui" machines.desktop.vpn.nextjsOllamaPort)
    ];

  # Persistence
  environment.persistence."/var/residues".directories = [
    "/var/lib/llama-cpp"
    "/var/lib/ollama"
  ];

  # ROCm
  environment.systemPackages = with pkgs; [
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
  ];
}
