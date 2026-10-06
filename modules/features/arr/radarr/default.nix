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
          default = true;
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
          };
        };
      };
    };
}
