{ self, inputs, ... }: {
  flake.nixosModules.matrixHomeServer =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.matrix;
    in
    {
      options = {
        services.matrix = {
          domain = lib.mkOption {
            default = config.domain;
            type = lib.types.str;
          };

          mautrix.discord = {
            environmentFile = lib.mkOption {
              default = config.sops.secrets."mautrix/env".path;
              type = lib.types.path;
              description = ''
                File with env var definitions used by mautrix discord settings.
                Read definition in this module for vars to define in this file.
              '';
            };
            dataDir = lib.mkOption {
              default = config.disko.devices.zpool.fast.datasets."encrypted/app/mautrix-discord".mountpoint;
              type = lib.types.path;
            };
          };
        };
      };

      config = {
        security.acme = {
          certs."matrix.${cfg.domain}" = {
            domain = "matrix.${cfg.domain}";
          };
        };

        services.caddy = {
          virtualHosts."${cfg.domain}" = {
            extraConfig = ''
              handle /.well-known/matrix/server {
                respond `{"m.server": "matrix.${cfg.domain}:443"}`
                header Content-Type application/json
              }

              handle /.well-known/matrix/client {
                respond `{"m.homeserver":{"base_url":"https://matrix.${cfg.domain}"}}`
                header Content-Type application/json
                header Access-Control-Allow-Origin *
              }

              log_skip /.well-known*

            '';
            useACMEHost = config.certs.wildcard.acmeHost;
          };

          virtualHosts."matrix.${cfg.domain}" = {
            useACMEHost = "matrix.${cfg.domain}";
            extraConfig = ''
              reverse_proxy http://localhost:6167
            '';
          };
        };

        services.matrix-continuwuity = {
          enable = true;
          settings = {
            global = {
              server_name = cfg.domain;
              allow_registration = false;
              allow_encryption = true;
              allow_federation = true;
              trusted_servers = [ "matrix.org" ];
              # 5GiB
              max_request_size = 5368709120;
              # also allow sub domains
              url_preview_check_root_domain = true;
              url_preview_domain_explicit_allowlist = [
                cfg.domain
                "google.com"
                "youtube.com"
                "youtu.be"
                "imgur.com"
                "puush.me"
                "amazon.com"
                "x.com"
                "reddit.com"
                "stackoverflow.com"
                "stackexchange.com"
                "superuser.com"
                "github.com"
                "gitlab.com"
                "wikipedia.org"
                "nixos.org"
                "nixos.wiki"
                "archlinux.org"
                "xkcd.com"
                "duckduckgo.com"
                "microsoft.com"
                "cppreference.com"
                "man7.org"
                "matrix.org"
                "continuwuity.org"
              ];
            };
          };
        };

        # TODO: reevaluate
        nixpkgs.config.permittedInsecurePackages = [
          "olm-3.2.16"
        ];

        services.mautrix-discord = {
          enable = true;

          inherit (cfg.mautrix.discord) dataDir environmentFile;

          settings = {
            homeserver = {
              inherit (config) domain;
              address = "https://matrix.${cfg.domain}";
            };
            appservice = {
              database = {
                type = "sqlite3-fk-wal";
                uri = "file:${cfg.mautrix.discord.dataDir}/mautrix-discord.db?_txlock=immediate";
              };
            };
            bridge = {
              permissions = {
                "$mxid_me" = "admin";
                "$mxid_friend1" = "user";
                "$mxid_friend2" = "user";
                "$mxid_friend3" = "user";
              };
              double_puppet_server_map = {
                "${cfg.domain}" = "$double_puppet_as_token";
              };
              backfill = {
                forward_limits = {
                  initial = {
                    dm = 1000000;
                    channel = 1000000;
                    thread = 1000;
                  };
                  missed = {
                    dm = -1;
                    channel = -1;
                    thread = -1;
                  };
                };
              };
              encryption = {
                allow = true;
                default = true;
                allow_key_sharing = true;
              };
            };
          };
        };
      };
    };
}
