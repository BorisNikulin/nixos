{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.caddy = moduleWithSystem (
    {
      self',
      input',
      pkgs,
      ...
    }:
    {
      lib,
      config,
      ...
    }:
    {
      services.caddy = {
        enable = true;
        openFirewall = true;

        globalConfig = ''
          metrics {
            per_host
          }

          servers {
            import ${self'.packages.caddyCloudflareTrustedProxies}
            client_ip_headers CF-Connecting-IP
            trusted_proxies_strict
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
    }
  );

  perSystem = { self', pkgs, ... }: {
    packages.cloudflareIpsJson = pkgs.fetchurl {
      name = "cloudflare-ips.json";
      url = "https://api.cloudflare.com/client/v4/ips";
      sha256 = "1zaymjn33akhq4sr4v43fcdh3ymra0yh78bs62lakm5gd1bs7l7k";
    };
    packages.caddyCloudflareTrustedProxies =
      let
        data = builtins.fromJSON (builtins.readFile self'.packages.cloudflareIpsJson);
        allIps = builtins.concatStringsSep " " (data.result.ipv4_cidrs ++ data.result.ipv6_cidrs);
      in
      pkgs.writeText "cloudflare-trusted-proxies.caddy" ''
        trusted_proxies static ${allIps}
      '';
  };
}
