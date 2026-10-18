{ self, inputs, ... }: {
  flake.nixosModules.prowlarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.prowlarr;
    in
    {
      options.prowlarr = {
        dataDir = lib.mkOption {
          default = config.disko.devices.zpool.fast.datasets."encrypted/app/prowlarr".options.mountpoint;
          type = lib.types.str;
        };
        openFirewall = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
      };

      config = {
        services.prowlarr = {
          enable = true;
          dataDir = cfg.dataDir;
          openFirewall = cfg.openFirewall;
          environmentFiles = [ config.sops.templates."arr-prowlarr-api-key".path ];
          settings = {
            update.automatically = false;
            log.analyticsEnabled = false;
            Auth.Method = "External";
          };
        };

        auth.apps.prowlarr = {
          domain = "prowlarr.${config.domain}";
          groups = {
            admin = "prowlarr-admin";
          };
        };

        services.caddy.virtualHosts."prowlarr.${config.domain}" = {
          useACMEHost = config.certs.wildcard.acmeHost;
          extraConfig = ''
            ${config.auth.forwardAuth.caddyForwardAuth { }}
            reverse_proxy http://localhost:${toString config.services.prowlarr.settings.server.port}
          '';
        };
      };
    };
}
