{ ssot, ... }: with ssot;

{
  services.pds = {
    enable = true;
    environmentFiles = [ "/var/persistent/secrets/bsky-pds.env" ];
    settings = {
      PDS_PORT = machines.lab.loopback.bskyPort;
      PDS_HOSTNAME = web.bsky.addr;
    };
  };
}
