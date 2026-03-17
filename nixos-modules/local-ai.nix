{ pkgs, ssot, lib, config, ... }@args: with ssot.machines.desktop.vpn;

let
  proxyAddr = config.services.lazy-proxy.targetAddr;
in
{
  # Ollama
  services.ollama = {
    enable = true;
    host = proxyAddr;
    port = ollamaPort;
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

  # User-based Ollama home
  systemd.services.ollama = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      RestrictNamespaces = lib.mkForce false;
    };
  };

  # I'll call the model loader by hand
  systemd.services.ollama-model-loader.wantedBy = lib.mkForce [ ];

  # Ollama Web UI
  services.nextjs-ollama-llm-ui = {
    enable = true;
    hostname = proxyAddr;
    port = nextjsOllamaPort;
    ollamaUrl = "http://${v4}:${toString ollamaPort}";
  };

  # Llama-Cpp
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-vulkan;
    host = proxyAddr;
    port = llamaCppPort;
    model = "${config.users.users.llama-cpp.home}/models/Qwen3.5-35B-A3B-Q3_K_S.gguf";
    extraFlags = [
      "-ngl"
      "99"
      "-c"
      "32768"
      "--flash-attn"
      "on"
      "--cache-type-k"
      "q8_0"
      "--cache-type-v"
      "q8_0"
      "--parallel"
      "1"
      "--chat-template-kwargs"
      "{\"enable_thinking\":false}"
    ];
  };

  # User-based Llama-Cpp home
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
  };

  # Systemd lazy-activated sockets
  imports = [ ./lazy-proxy.nix ];

  services.lazy-proxy = {
    enable = true;

    bindIPv4 = v4;
    bindIPv6 = v6;

    proxies = {
      ollama.port = ollamaPort;
      nextjs-ollama-llm-ui.port = nextjsOllamaPort;
      llama-cpp.port = llamaCppPort;
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
