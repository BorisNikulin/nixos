{ self, inputs, ... }: {
  flake.nixosModules.radarr =
    { config, lib, ... }:
    let
      cfg = config.radarr;
    in
    {
      options.radarr = {
        dataDir = lib.mkOption {
          default = config.disko.devices.zpool.fast.datasets."encrypted/app/radarr".options.mountpoint;
          type = lib.types.str;
        };
        openFirewall = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
      };

      config = {
        services.radarr = {
          enable = true;
          dataDir = cfg.dataDir;
          group = "media";
          openFirewall = cfg.openFirewall;
          environmentFiles = [ config.sops.templates."arr-radarr-api-key".path ];
          settings = {
            update.automatically = false;
            log.analyticsEnabled = false;
            Auth.Method = "External";
          };
        };

        auth.apps.radarr = {
          domain = "radarr.${config.domain}";
          groups = {
            admin = "radarr-admin";
          };
        };

        services.caddy.virtualHosts."radarr.${config.domain}" = {
          useACMEHost = config.certs.wildcard.acmeHost;
          extraConfig = ''
            ${config.auth.forwardAuth.caddyForwardAuth { }}
            reverse_proxy http://localhost:${toString config.services.radarr.settings.server.port}
          '';
        };
      };
    };
}
