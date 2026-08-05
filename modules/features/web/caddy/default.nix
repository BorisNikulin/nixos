{ self, inputs, ... }: {
  flake.nixosModules.caddy =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      services.caddy = {
        enable = true;

        globalConfig = ''
          metrics {
            per_host
          }
        '';
      };

      services.prometheus = {
        scrapeConfigs = [
          {
            job_name = "caddy";
            scrape_interval = "15s";
            static_configs = [
              {
                targets = [ "localhost:2019" ];
              }
            ];
          }
        ];
      };
    };

}
