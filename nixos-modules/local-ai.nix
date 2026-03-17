{ pkgs, ssot, lib, config, ... }@args: with ssot;

let
  proxyAddr = "127.0.0.23";
in
{
  # AI (Ollama)
  services.ollama = {
    enable = true;
    host = config.services.lazy-proxy.targetAddr;
    port = machines.desktop.vpn.ollamaPort;
    package = pkgs.ollama-vulkan;
    loadModels = [ "qwen3-coder:30b" "gpt-oss:20b" ];
    syncModels = true;
    user = "ollama";
    group = "agents";
    # rocmOverrideGfx = "10.3.0";
    environmentVariables = {
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_FLASH_ATTENTION = "1";
    };
  };
  systemd.services.ollama = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      RestrictNamespaces = lib.mkForce false;
    };
  };

  # I'll call the model loader by hand
  systemd.services.ollama-model-loader.wantedBy = lib.mkForce [ ];

  # AI (ollama chat)
  services.nextjs-ollama-llm-ui = {
    enable = true;
    hostname = config.services.lazy-proxy.targetAddr;
    port = machines.desktop.vpn.nextjsOllamaPort;
    ollamaUrl = "http://${machines.desktop.vpn.v4}:${toString machines.desktop.vpn.ollamaPort}";
  };

  # AI (systemd activation sockets)
  imports = [ ./lazy-proxy.nix ];

  services.lazy-proxy = {
    enable = true;

    bindIPv4 = machines.desktop.vpn.v4;
    bindIPv6 = machines.desktop.vpn.v6;

    proxies = {
      ollama.port = ssot.machines.desktop.vpn.ollamaPort;
      nextjs-ollama-llm-ui.port = ssot.machines.desktop.vpn.nextjsOllamaPort;
    };
  };

  # Persistence
  environment.persistence."/var/residues".directories = [
    "/var/lib/llama-cpp"
    "/var/lib/ollama"
  ];

  # ROCm
  # environment.systemPackages = with pkgs; [
  #   rocmPackages.rocminfo
  #   rocmPackages.rocm-smi
  # ];
}
