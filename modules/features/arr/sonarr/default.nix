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
          default = true;
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
          };
        };
      };
    };
}
