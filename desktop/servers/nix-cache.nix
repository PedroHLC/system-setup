{ config, ... }:
{
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/home/pedrohlc/Projects/com.pedrohlc/binary-cache/cache-priv-key.pem";
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      # ... existing hosts config etc. ...
      "nix-cache.pedrohlc.com" = {
        serverAliases = [ "nix-cache" ];
        locations."/".extraConfig = ''
          proxy_pass http://localhost:${toString config.services.nix-serve.port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };
  };
}
