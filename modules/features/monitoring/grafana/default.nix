{ self, inputs, ... }: {
  flake.nixosModules.grafana =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.monitoring.grafana;
    in
    {
      options.services.monitoring.grafana = {
        dataDir = lib.mkOption {
          default = config.disko.devices.zpool.fast.datasets."encrypted/app/grafana".options.mountpoint;
          type = lib.types.path;
        };
        secretKeyFile = lib.mkOption {
          default = config.sops.secrets."grafana/secret_key".path;
          type = lib.types.path;
        };
      };
      config = {
        services.grafana = {
          enable = true;

          inherit (cfg) dataDir;
          openFirewall = false;

          settings = {
            security = {
              secret_key = "$__file{${cfg.secretKeyFile}}";
            };
            server = {
              http_addr = "127.0.0.1";
              http_port = 3000;
              domain = "grafana.${config.domain}";
              enable_gzip = true;
            };

            "auth.proxy" = {
              enabled = true;
              header_name = "Remote-User";
              headers = "Name:Remote-Name Email:Remote-Email Groups:Remote-Groups Role:Remote-Role";
              whitelist = "127.0.0.1, ::1";
              # Resync org role (permissions) faster than 15m default.
              sync_ttl = 2;
            };

            analytics.reporting_enabled = false;
          };
          provision = {
            enable = true;

            # Pulls dashboards from /etc/grafana-dashboards (served from
            # ./dashboards below). Re-editing the JSON and rebuilding replaces
            # the dashboard in place, keyed by its uid.
            # Export from Grafana: dashboard menu -> Export -> copy the JSON.
            dashboards.settings.providers = [
              {
                name = "Dashboards";
                disableDeletion = true;
                options = {
                  path = "/etc/grafana-dashboards";
                  foldersFromFilesStructure = true;
                };
              }
            ];

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

        environment.etc."grafana-dashboards".source = ./dashboards;

        auth.apps.grafana = {
          domain = "grafana.${config.domain}";
          groups = {
            view = "grafana";
            admin = "grafana-admin";
          };
        };

        services.caddy = {
          virtualHosts."grafana.${config.domain}" = {
            useACMEHost = config.certs.wildcard.acmeHost;
            extraConfig = ''
              # Enable logout without enabling session cookie in grafana.
              redir /logout https://auth.${config.domain}/logout 302

              # Manually set role (permissions) header if group contains grafana admin group.
              @grafana header Remote-Groups "*${config.auth.apps.grafana.groups.admin}*"
              ${config.auth.forwardAuth.caddyForwardAuth { }}
              request_header @grafana Remote-Role "Admin"

              reverse_proxy http://localhost:${toString config.services.grafana.settings.server.http_port}
            '';
          };
        };
      };
    };
}
