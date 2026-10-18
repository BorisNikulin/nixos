{ self, inputs, ... }: {
  flake.nixosModules.sonarr =
    { config, lib, ... }:
    let
      cfg = config.sonarr;
    in
    {
      options.sonarr = {
        dataDir = lib.mkOption {
          default = config.disko.devices.zpool.fast.datasets."encrypted/app/sonarr".options.mountpoint;
          type = lib.types.str;
        };
        openFirewall = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
      };

      config = {
        services.sonarr = {
          enable = true;
          dataDir = cfg.dataDir;
          group = "media";
          openFirewall = cfg.openFirewall;
          environmentFiles = [ config.sops.templates."arr-sonarr-api-key".path ];
          settings = {
            update.automatically = false;
            log.analyticsEnabled = false;
            Auth.Method = "External";
          };
        };

        auth.apps.sonarr = {
          domain = "sonarr.${config.domain}";
          groups = {
            admin = "sonarr-admin";
          };
        };

        services.caddy.virtualHosts."sonarr.${config.domain}" = {
          useACMEHost = config.certs.wildcard.acmeHost;
          extraConfig = ''
            ${config.auth.forwardAuth.caddyForwardAuth { }}
            reverse_proxy http://localhost:${toString config.services.sonarr.settings.server.port}
          '';
        };
      };
    };
}
