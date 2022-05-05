{ config, ... }:
{
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/home/pedrohlc/Projects/com.pedrohlc/binary-cache/cache-priv-key.pem";
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
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

  nixpkgs.overlays = [
    (self: super: {
      nix-serve = super.nix-serve.overrideAttrs (attrs: {
        src = self.fetchFromGitHub {
          owner = "PedroHLC";
          repo = "nix-serve";
          rev = "53b65e7250005d742c72d0123e379e7c7fb7d41c";
          sha256 = "2CylBS0Y50PzxrDQvX368slpU4z1fpaRPK1350yMttg=";
        };
        version = "0.2-53b65e7";
      });
    })
  ];
}
