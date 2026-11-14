{ ai-memory, machines, pkgs, ... }:
{
  home.packages = [ ai-memory.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  home.sessionVariables.AI_MEMORY_SERVER_URL = "http://${machines.lab.vpn.v4}:${toString machines.lab.vpn.aiMemoryPort}";
  programs.codex = {
    enable = true;
    mutableSettings = true;
    plugins = [ (ai-memory + /plugins/codex) ];
  };
}
