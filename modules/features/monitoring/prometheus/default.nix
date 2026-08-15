{ self, inputs, ... }: {
  flake.nixosModules.monitoring =
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
      options = {
        services.monitoring = {
          airgradientMetricsEndpoint = lib.mkOption {
            default = "bedroom.airgradient.home.arpa";
            type = lib.types.str;
          };

          grafana = {
            dataDir = lib.mkOption {
              default = config.disko.devices.zpool.fast.datasets."encrypted/app/grafana".mountpoint;
              type = lib.types.path;
            };

            secretKeyFile = lib.mkOption {
              default = config.sops.secrets."grafana/secret_key".path;
              type = lib.types.path;
            };
          };
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

        services.grafana = {
          enable = true;

          inherit (cfg.grafana) dataDir;
          openFirewall = true;

          settings = {
            security = {
              secret_key = "$__file{${cfg.grafana.secretKeyFile}}";
            };
            server = {
              http_addr = "0.0.0.0";
              http_port = 3000;
              domain = "grafana.${config.domain}";

              enable_gzip = true;
            };

            analytics.reporting_enabled = false;
          };
          provision = {
            enable = true;

            # Creates a *mutable* dashboard provider, pulling from /etc/grafana-dashboards.
            # With this, you can manually provision dashboards from JSON with `environment.etc` like below.
            # TODO: export fixed airgradient dashboard + node and caddy ones
            # and configure/upload them here.
            # dashboards.settings.providers = [
            #   {
            #     name = "Dashboards";
            #     disableDeletion = true;
            #     options = {
            #       path = "/etc/grafana-dashboards";
            #       foldersFromFilesStructure = true;
            #     };
            #   }
            # ];

            datasources.settings.datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
                isDefault = true;
                editable = false;
              }
            ];
          };
        };

        # see `dashboards.settings.providers` above and the associated TODO
        # environment.etc."grafana-dashboards/airgradient.json".source =
        #  ./grafana-dashboards/airgradient.json;

        services.caddy = {
          virtualHosts."grafana.${config.domain}" = {
            useACMEHost = config.certs.wildcard.acmeHost;
            extraConfig = ''
              reverse_proxy http://localhost:${toString config.services.grafana.settings.server.http_port}
            '';
          };
        };
      };
    };
}
