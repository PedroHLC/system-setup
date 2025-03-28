{ ssot, ... }: with ssot;

{
  services.pds = {
    enable = true;
    environmentFiles = [ "/var/persistent/secrets/bsky-pds.env" ];
    settings = {
      PDS_PORT = vpn.lab.bskyPort;
      PDS_HOSTNAME = web.bsky.addr;
    };
  };
}
