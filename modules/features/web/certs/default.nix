{ self, inputs, ... }: {
  flake.nixosModules.certs =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.certs;
    in
    {
      options = {
        certs = {
          cloudflareDnsApiTokenPath = lib.mkOption {
            default = config.sops.secrets."cloudflare/dns_api_token".path;
            type = lib.types.str;
          };

          default = {
            group = lib.mkOption {
              default = config.services.caddy.group;
              type = lib.types.str;
            };
          };

          wildcard = {
            reloadServices = lib.mkOption {
              default = [ config.systemd.services.caddy.name ];
              type = lib.types.listOf lib.types.str;
            };

            acmeHost = lib.mkOption {
              default = config.domain;
              type = lib.types.str;
              readOnly = true;
            };
          };
        };
      };

      config = {
        security.acme = {
          acceptTerms = true;
          defaults = {
            email = "NikulinBE@gmail.com";

            group = cfg.default.group;

            dnsProvider = "cloudflare";
            dnsPropagationCheck = true;
            environmentFile = cfg.cloudflareDnsApiTokenPath;
          };

          certs.${config.domain} = {
            inherit (config) domain;
            extraDomainNames = [
              "*.${config.domain}"
            ];

            reloadServices = cfg.wildcard.reloadServices;
          };
        };
      };
    };
}
