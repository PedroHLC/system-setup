{ ssot, ... }: with ssot;

{
  services.atuin = {
    enable = true;

    host = machines.lab.vpn.v4;
    port = machines.lab.vpn.atuinPort;
    openRegistration = true;
    maxHistoryLength = 1175664;
    database.createLocally = true;
  };
}
