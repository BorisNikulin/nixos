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
      keyFile = "/run/livekit.key";

      matrixServerConfig = {
        "m.server" = "matrix.${cfg.domain}:443";
      };
      matrixClientConfig = {
        "m.homeserver" = {
          base_url = "https://matrix.${cfg.domain}";
        };
        "org.matrix.msc4143.rtc_foci" = [
          {
            type = "livekit";
            livekit_service_url = "https://livekit.${cfg.domain}";
          }
        ];
      };
    in
    {
      options = {
        services.matrix = {
          domain = lib.mkOption {
            default = config.domain;
            type = lib.types.str;
          };

        };
      };

      config = {
        systemd.services.livekit = {
          serviceConfig.LoadCredential =
            let
              certDir = config.security.acme.certs."livekit-turn.${cfg.domain}".directory;
            in
            [
              "cert:${certDir}/cert.pem"
              "key:${certDir}/key.pem"
            ];
          environment = {
            # https://github.com/livekit/livekit/blob/35fe831f1d431bcc82021d1bf191327d366a7469/config-sample.yaml#L291
            LIVEKIT_TURN_CERT = "%d/cert";
            LIVEKIT_TURN_KEY = "%d/key";
          };
        };

        security.acme = {
          certs."matrix.${cfg.domain}" = {
            domain = "matrix.${cfg.domain}";
          };

          certs."livekit-turn.${cfg.domain}" = {
            domain = "livekit-turn.${cfg.domain}";

            # group = config.systemd.services.livekit.serviceConfig.Group;
            # group = "livekit";
            reloadServices = [ config.systemd.services.livekit.name ];
          };
        };

        services.caddy = {
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/mholt/caddy-l4@v0.1.2" ];
            hash = "sha256-UIv8PxtJMlX7qClnPazFsSSl7G1BzsTT8VjrMIfB46Q=";
          };
          # globalConfig = ''
          #   servers {
          #     listener_wrappers {
          #       # intercept packets meant for the TURN domain first
          #       # before forwarding other packets to "normal" HTTP listeners
          #       layer4 {
          #         @turn tls sni livekit-turn.${cfg.domain}
          #         route @turn {
          #           proxy localhost:${toString config.services.livekit.settings.turn.tls_port}
          #         }
          #       }
          #       tls
          #     }
          #   }
          # '';
          virtualHosts."${cfg.domain}" = {
            useACMEHost = config.certs.wildcard.acmeHost;
            extraConfig = ''
              handle /.well-known/matrix/server {
                respond `${builtins.toJSON matrixServerConfig}`
                header Content-Type application/json
              }

              handle /.well-known/matrix/client {
                respond `${builtins.toJSON matrixClientConfig}`
                header Content-Type application/json
                header Access-Control-Allow-Origin *
              }

              log_skip /.well-known*
            '';
          };

          virtualHosts."matrix.${cfg.domain}" = {
            useACMEHost = "matrix.${cfg.domain}";
            extraConfig = ''
              reverse_proxy http://localhost:6167
            '';
          };

          virtualHosts."livekit.${cfg.domain}" = {
            useACMEHost = config.certs.wildcard.acmeHost;
            extraConfig = ''
              @lk-jwt-service path /sfu/get* /healthz* /get_token*
              route @lk-jwt-service {
                  reverse_proxy http://localhost:${toString config.services.lk-jwt-service.port}
              }

              reverse_proxy http://localhost:${toString config.services.livekit.settings.port}
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

              # inherit (matrixClientConfig."m.homeserver") matrix_rtc;
              matrix_rtc = {
                foci = matrixClientConfig."org.matrix.msc4143.rtc_foci";
              };

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

        services.livekit = {
          enable = true;

          openFirewall = true;
          inherit keyFile;
          settings = {
            room.auto_create = false;

            rtc = {
              # make sure these ports are publically reachable
              port_range_start = 50000;
              port_range_end = 50100;
            };

            turn = {
              enabled = true;
              udp_port = 3478;
              tls_port = 5349;

              relay_range_start = 50300;
              relay_range_end = 50400;

              domain = "livekit-turn.${cfg.domain}";

              # cert_file = "/var/lib/acme/livekit-turn.${cfg.domain}/cert.pem";
              # key_file = "/var/lib/acme/livekit-turn.${cfg.domain}/key.pem";
            };
          };
        };

        services.lk-jwt-service = {
          enable = true;

          livekitUrl = "wss://livekit.${cfg.domain}";
          inherit keyFile;
        };
        # restrict access to livekit room creation to a homeserver
        # systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS = cfg.domain;

        # generate the key when needed
        systemd.services.livekit-key = {
          before = [
            config.systemd.services.lk-jwt-service.name
            config.systemd.services.livekit.name
          ];
          wantedBy = [ "multi-user.target" ];

          path = with pkgs; [
            livekit
            coreutils
            gawk
          ];
          script = ''
            echo "Key missing, generating key"
            echo "lk-jwt-service: $(livekit-server generate-keys | tail -1 | awk '{print $3}')" > "${keyFile}"
          '';

          serviceConfig.Type = "oneshot";
          unitConfig.ConditionPathExists = "!${keyFile}";

        };

        # TODO: reevaluate
        nixpkgs.config.permittedInsecurePackages = [
          "olm-3.2.16"
        ];

      };
    };
}
