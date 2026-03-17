{ config, lib, pkgs, ... }:

/**
 * Lazy-Proxy Module:
 * On-demand service activation via systemd-socket-proxyd.
 * Bridges public/VPN interfaces to internal-only services (e.g., 127.0.0.23),
 * ensuring backend units only consume resources when they actually receive traffic.
 */
let
  cfg = config.services.lazy-proxy;
  inherit (lib) mkOption types mkIf mkMerge mkForce genAttrs;

  servicesNames = lib.attrNames cfg.proxies;
  proxyNames = map (n: "proxy-${n}") servicesNames;
in
{
  options.services.lazy-proxy = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    targetAddr = mkOption {
      type = types.str;
      default = "127.0.0.23";
      description = "The internal IP the actual services listen on (backend).";
    };

    bindIPv4 = mkOption {
      type = types.str;
      description = "The IPv4 address the proxy should listen on (frontend).";
    };

    bindIPv6 = mkOption {
      type = types.str;
      description = "The IPv6 address the proxy should listen on (frontend).";
    };

    proxies = mkOption {
      description = "Map of unit names to their ports.";
      default = { };
      type = types.attrsOf (types.submodule {
        options = {
          port = mkOption { type = types.port; };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    assertions = map
      (name: {
        assertion = config.systemd.services ? ${name};
        message = "lazy-proxy: Target service '${name}' not found in systemd.services.";
      })
      servicesNames;

    systemd.services = mkMerge [
      # 1. Gently suggest target services stay dormant
      (genAttrs servicesNames (name: {
        wantedBy = lib.mkOverride 90 [ ];
      }))

      # 2. Define the proxy forwarders
      (genAttrs proxyNames (proxyName:
        let
          name = lib.removePrefix "proxy-" proxyName;
          inherit (cfg.proxies.${name}) port;
        in
        {
          description = "Lazy activation proxy for ${name}";

          after = [ "${name}.service" "${proxyName}.socket" ];
          requires = [ "${name}.service" "${proxyName}.socket" ];

          serviceConfig = {
            Type = "notify";
            ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${cfg.targetAddr}:${toString port}";
            PrivateTmp = true;
          };
        })
      )
    ];

    systemd.sockets = genAttrs proxyNames (proxyName:
      let
        name = lib.removePrefix "proxy-" proxyName;
        inherit (cfg.proxies.${name}) port;
      in
      {
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenStream = [
            "${cfg.bindIPv4}:${toString port}"
            "[${cfg.bindIPv6}]:${toString port}"
          ];
          NoDelay = true;
          FreeBind = true;
        };
      });
  };
}
