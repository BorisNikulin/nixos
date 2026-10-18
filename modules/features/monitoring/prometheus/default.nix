{ self, inputs, ... }: {
  flake.nixosModules.prometheus =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.monitoring;
    in
    {
      options.services.monitoring = {
        airgradientMetricsEndpoint = lib.mkOption {
          default = "bedroom.airgradient.home.arpa";
          type = lib.types.str;
        };
      };
      config = {
        # https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/monitoring/prometheus/exporters/node.nix
        services.prometheus.exporters.node = {
          enable = true;
          port = 9002;
          # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
          enabledCollectors = [
            "systemd"
            "ethtool"
          ];
          # /nix/store/zgsw0yx18v10xa58psanfabmg95nl2bb-node_exporter-1.8.1/bin/node_exporter  --help
        };

        # https://wiki.nixos.org/wiki/Prometheus
        # https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters-configuration
        # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/default.nix
        services.prometheus = {
          enable = true;
          port = 9001;
          stateDir = "prometheus"; # /var/lib/prometheus
          globalConfig.scrape_interval = "1m";
          scrapeConfigs = [
            {
              job_name = "node";
              static_configs = [
                {
                  targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
                }
              ];
            }
            {
              job_name = "airgradient_bedroom";
              scrape_interval = "30s";
              static_configs = [
                {
                  targets = [ cfg.airgradientMetricsEndpoint ];
                }
              ];
            }
          ];
        };
      };
    };
}
