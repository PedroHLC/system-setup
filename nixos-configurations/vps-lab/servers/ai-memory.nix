{ ssot, ... }: with ssot;

{
  services.ai-memory = {
    enable = true;
    bind = machines.lab.vpn.v4;
    port = machines.lab.vpn.aiMemoryPort;
    environmentFile = "/var/persistent/secrets/ai-memory.env";
  };

  systemd.services.ai-memory = {
    after = [ "wireguard-wg0.service" ];
    requires = [ "wireguard-wg0.service" ];
  };
}
