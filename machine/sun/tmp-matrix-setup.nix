{ pkgs, config, ... }:
let
  domain = "rhakotis.xyz";
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "NikulinBE@gmail.com";

    certs."${domain}" = {
      group = config.services.caddy.group;

      inherit domain;
      extraDomainNames = [
        "*.${domain}"
      ];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets."cloudflare/dns_api_token".path;
    };

    certs."matrix.${domain}" = {
      group = config.services.caddy.group;

      domain = "matrix.${domain}";
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets."cloudflare/dns_api_token".path;
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts."${domain}".extraConfig = ''
      handle /.well-known/matrix/server {
        respond `{"m.server": "matrix.${domain}:443"}`
        header Content-Type application/json
      }

      handle /.well-known/matrix/client {
        respond `{"m.homeserver":{"base_url":"https://matrix.${domain}"}}`
        header Content-Type application/json
        header Access-Control-Allow-Origin *
      }

      log_skip /.well-known*

      tls /var/lib/acme/${domain}/cert.pem /var/lib/acme/${domain}/key.pem {
        protocols tls1.3
      }
    '';

    virtualHosts."matrix.${domain}" = {
      useACMEHost = "matrix.${domain}";
      extraConfig = ''
        reverse_proxy http://localhost:6167  
      '';
    };
  };

  services.matrix-continuwuity = {
    enable = true;
    settings = {
      global = {
        server_name = domain;
        allow_registration = false;
        allow_encryption = true;
        allow_federation = true;
        trusted_servers = [ "matrix.org" ];
        url_preview_domain_explicit_allowlist = [
          domain
          "google.com"
          "youtube.com"
          "www.youtube.com"
          "imgur.com"
          "i.imgur.com"
          "puush.me"
          "amazon.com"
          "x.com"
          "reddit.com"
          "www.reddit.com"
          "stackoverflow.com"
          "stackexchange.com"
          "superuser.com"
          "github.com"
          "gitlab.com"
          "wikipedia.org"
          "nixos.org"
          "nixos.wiki"
          "archlinux.org"
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
        inherit domain;
        address = "https://matrix.${domain}";
      };
      appservice = {
        database = {
          type = "sqlite3-fk-wal";
          uri = "file:${config.disko.devices.zpool.fast.datasets."encrypted/app/mautrix-discord".mountpoint}/mautrix-discord.db?_txlock=immediate";
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
          "${domain}" = "$double_puppet_as_token";
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
}
