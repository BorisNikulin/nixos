{ self, inputs, ... }: {
  flake.nixosModules.matrixHomeServer =
    { pkgs, config, ... }:
    {
      security.acme = {
        certs."matrix.${config.domain}" = {
          domain = "matrix.${config.domain}";
        };
      };

      services.caddy = {
        virtualHosts."${config.domain}" = {
          extraConfig = ''
            handle /.well-known/matrix/server {
              respond `{"m.server": "matrix.${config.domain}:443"}`
              header Content-Type application/json
            }

            handle /.well-known/matrix/client {
              respond `{"m.homeserver":{"base_url":"https://matrix.${config.domain}"}}`
              header Content-Type application/json
              header Access-Control-Allow-Origin *
            }

            log_skip /.well-known*

          '';
          useACMEHost = config.certs.wildcard.acmeHost;
        };

        virtualHosts."matrix.${config.domain}" = {
          useACMEHost = "matrix.${config.domain}";
          extraConfig = ''
            reverse_proxy http://localhost:6167  
          '';
        };
      };

      services.matrix-continuwuity = {
        enable = true;
        settings = {
          global = {
            server_name = config.domain;
            allow_registration = false;
            allow_encryption = true;
            allow_federation = true;
            trusted_servers = [ "matrix.org" ];
            # 5GiB
            max_request_size = 5368709120;
            # also allow sub domains
            url_preview_check_root_domain = true;
            url_preview_domain_explicit_allowlist = [
              config.domain
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
        dataDir = config.disko.devices.zpool.fast.datasets."encrypted/app/mautrix-discord".mountpoint;
        environmentFile = config.sops.secrets."mautrix/env".path;
        settings = {
          homeserver = {
            inherit (config) domain;
            address = "https://matrix.${config.domain}";
          };
          appservice = {
            database = {
              type = "sqlite3-fk-wal";
              uri = "file:${
                config.disko.devices.zpool.fast.datasets."encrypted/app/mautrix-discord".mountpoint
              }/mautrix-discord.db?_txlock=immediate";
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
              "${config.domain}" = "$double_puppet_as_token";
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
}
