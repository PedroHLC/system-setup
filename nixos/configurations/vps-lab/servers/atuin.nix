{ ssot, ... }: with ssot;

{
  services.atuin = {
    enable = true;

    host = vpn.lab.v4;
    openRegistration = true;
    maxHistoryLength = 1175664;
    database.createLocally = true;
  };
}
