{ config, lib, pkgs, ssot, flakes, ... }: with ssot;
# Adapted from:
# https://gitlab.com/famedly/conduit/-/blob/3bfdae795d4d9ec9aeaac7465e7535ac88e47756/nix/README.md
let
  matrix_hostname = web.dev.addr;

  matrix_hostname_regex = lib.strings.escapeRegex matrix_hostname;

  well_known_server = pkgs.writeText "well-known-matrix-server" ''
    {
      "m.server": "${matrix_hostname}"
    }
  '';

  well_known_client = pkgs.writeText "well-known-matrix-client" ''
    {
      "m.homeserver": {
        "base_url": "https://${matrix_hostname}"
      }
    }
  '';
in
{
  services.matrix-conduit = {
    enable = true;
    package = pkgs.conduwuit_git;
    settings.global = {
      server_name = matrix_hostname;
      allow_registration = false;
      database_backend = "rocksdb";
      trusted_servers = [ "envs.net" ];
    };
  };
  services.nginx = {
    virtualHosts."${matrix_hostname}" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }
        {
          addr = "[::]";
          port = 443;
          ssl = true;
        }
        {
          addr = "0.0.0.0";
          port = 8448;
          ssl = true;
        }
        {
          addr = "[::]";
          port = 8448;
          ssl = true;
        }
      ];

      locations."/_matrix/" = {
        proxyPass = "http://backend_conduit$request_uri";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_buffering off;
        '';
      };
      locations."=/.well-known/matrix/server" = {
        alias = "${well_known_server}";

        extraConfig = ''
          default_type application/json;
        '';
      };
      locations."=/.well-known/matrix/client" = {
        alias = "${well_known_client}";

        extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin "*";
        '';
      };

      extraConfig = ''
        merge_slashes off;
      '';
    };

    upstreams = {
      "backend_conduit" = {
        servers = {
          "[::1]:${toString config.services.matrix-conduit.settings.global.port}" = { };
        };
      };
    };
  };

  # Telegram bridge
  services.mautrix-telegram = {
    enable = true;
    environmentFile = "/var/persistent/secrets/mautrix-telegram.env";
    serviceDependencies = [ "conduit.service" ];
    # https://github.com/mautrix/telegram/blob/v0.15.1/mautrix_telegram/example-config.yaml
    settings = {
      appservice = rec {
        port = 29317;
        address = "http://localhost:29317";
        id = "telegram";
        bot_displayname = "Chaotic-CX Telegram";
        bot_username = "telegrambot";
      };
      homeserver = {
        address = "https://${matrix_hostname}";
        domain = matrix_hostname;
      };
      bridge.permissions = {
        "${matrix_hostname}" = "full";
        "@admin:${matrix_hostname}" = "admin";
      };
    };
  };

  # Mautrix uses it
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];
}
