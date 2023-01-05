{ ssot, ... }: with ssot;
{
  services.libreddit = {
    enable = true;
    port = vpn.lab.libredditPort;
  };
}
