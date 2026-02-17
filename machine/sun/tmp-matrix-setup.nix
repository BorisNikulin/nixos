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

      domain = "${domain}";
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
      serverAliases = [ "matrix.${domain}:8448" ];
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
        server_name = "matrix.${domain}";
        allow_registration = true;
        registration_token = "1234567890";
        allow_encryption = true;
        allow_federation = true;
        trusted_servers = [ "matrix.org" ];
      };
    };
  };
}
