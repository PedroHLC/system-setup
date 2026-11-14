{ ai-memory, caveman, machines, pkgs, ... }:
{
  home.packages = [ ai-memory.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  home.sessionVariables.AI_MEMORY_SERVER_URL = "http://${machines.lab.vpn.v4}:${toString machines.lab.vpn.aiMemoryPort}";
  programs.codex = {
    enable = true;
    mutableSettings = true;
    plugins = [ (ai-memory + /plugins/codex) ];
    skills.caveman = caveman + /skills/caveman;
    context = ''
      Use the $caveman skill by default in every session, unless the user asks to stop.
    '';
  };
}
