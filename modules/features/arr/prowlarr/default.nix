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
          default = true;
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
          };
        };
      };
    };
}
