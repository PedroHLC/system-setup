{ ssot, ... }: with ssot;
{
  imports = [
    ../../../nixos-modules/postgres.nix
  ];

  services.niks3 = {
    enable = true;
    httpAddr = "${machines.lab.vpn.v4}:${toString machines.lab.vpn.niks3Port}";

    s3 = {
      endpoint = "583868f726db11a0c95b74acef15f386.r2.cloudflarestorage.com";
      bucket = "nyx";
      region = "auto";
      useSSL = true;
      accessKeyFile = "/var/persistent/secrets/niks3/r2-access-key";
      secretKeyFile = "/var/persistent/secrets/niks3/r2-secret-key";
    };

    apiTokenFile = "/var/persistent/secrets/niks3/api-token";

    signKeyFiles = [ "/var/persistent/secrets/niks3/signing-key" ];

    gc = {
      enable = true;
      olderThan = "720h";
      failedUploadsOlderThan = "6h";
      schedule = "daily";
      randomizedDelaySec = 1800;
    };

    nginx = {
      enable = true;
      domain = web.niks3.addr;
    };
  };
}
