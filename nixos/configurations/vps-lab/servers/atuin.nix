{ ssot, ... }: with ssot;

{
  services.atuin = {
    enable = true;

    host = vpn.lab.v4;
    port = vpn.lab.atuinPort;
    openRegistration = true;
    maxHistoryLength = 1175664;
    database.createLocally = true;
  };
}
