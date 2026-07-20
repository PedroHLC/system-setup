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

  tuwunel_1_8_2 =
    pkgs.fetchFromGitHub {
      owner = "matrix-construct";
      repo = "tuwunel";
      tag = "v1.8.2";
      hash = "sha256-mfdX5HmuXf6s7zyT9AJUoz4v5v9Km+VX8z6KvRGq8F8=";
    };
in
{
  services.matrix-tuwunel = {
    enable = true;
    package =
      if pkgs.matrix-tuwunel.version == "1.8.1" then
        pkgs.matrix-tuwunel.overrideAttrs (prevAttrs: {
          version = "1.8.2";
          src = tuwunel_1_8_2;
          cargoHash = "sha256-jIgL/4i17H216goZ8DiFvIJTCKyjEHGiky3MTO5sQoY=";
          cargoDeps = prevAttrs.cargoDeps.overrideAttrs (prevCargoAttrs: {
            src = tuwunel_1_8_2;
            vendorStaging = prevCargoAttrs.vendorStaging.overrideAttrs (_prevVendorAttrs: {
              outputHash = "sha256-jIgL/4i17H216goZ8DiFvIJTCKyjEHGiky3MTO5sQoY=";
            });
          });
        })
      else throw "Matrix-tuwunel bumped";
    settings.global = {
      server_name = matrix_hostname;
      allow_registration = false;
      database_backend = "rocksdb";
      trusted_servers = [ "envs.net" "matrix.org" ];
      sentry = true;
      dns_servers = [ "::1" "127.0.0.1" ];
    };
    # migrated
    group = "conduit";
    user = "conduit";
    stateDirectory = "matrix-conduit";
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
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          client_max_body_size 100m;
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
          "[::1]:${toString config.services.matrix-tuwunel.settings.global.port}" = { };
        };
      };
    };
  };

  users.users."conduit" = {
    group = "conduit";
    home = "/var/lib/matrix-conduit";
    description = "Matrix home-server";
    createHome = false;
    isSystemUser = true;
  };
  users.groups.conduit = { };

  # Telegram bridge
  services.mautrix-telegram = {
    enable = true;
    environmentFile = "/var/persistent/secrets/mautrix-telegram.env";
    serviceDependencies = [ "tuwunel.service" ];
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
}
