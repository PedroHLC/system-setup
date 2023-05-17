{ ssot, ... }: with ssot;
{
  services.atticd = {
    enable = true;

    # Replace with absolute path to your credentials file
    credentialsFile = "/var/persistent/secrets/atticd/creds.env";

    settings = {
      listen = "[::]:${builtins.toString vpn.lab.atticPort}";

      storage = {
        type = "s3";
        endpoint = "https://583868f726db11a0c95b74acef15f386.r2.cloudflarestorage.com/chaotic-nyx";
      };

      # WARNING: Once set, never change it.
      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };
}
