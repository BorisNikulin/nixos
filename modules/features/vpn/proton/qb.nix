{ self, inputs, ... }: {
  flake.nixosModules.vpnProtonQb =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.vpnProtonQb;
    in
    {
      options.vpnProtonQb = {
        interface = lib.mkOption {
          default = "wg-qb";
          type = lib.types.str;
          description = "WireGuard interface name, the SO_BINDTODEVICE target.";
        };

        keyFile = lib.mkOption {
          default = config.sops.secrets."proton/qb".path;
          type = lib.types.path;
          description = "WireGuard private key file.";
        };
      };

      config = {
        systemd.network.enable = true;

        systemd.network.netdevs."40-${cfg.interface}" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = cfg.interface;
          };
          wireguardConfig = {
            PrivateKeyFile = cfg.keyFile;
            ListenPort = 51820;
          };
          wireguardPeers = [
            {
              PublicKey = "MkUR6S5ObCzMx0ZToukggFecdUEjEM2GU/ZhLoz2ICY=";
              AllowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              Endpoint = "149.102.254.65:51820";
              PersistentKeepalive = 30;
            }
          ];
        };

        systemd.network.networks."40-${cfg.interface}" = {
          matchConfig.Name = cfg.interface;
          address = [ "10.2.0.2/32" ];
          linkConfig.RequiredForOnline = "no";
        };

        networking.networkmanager.unmanaged = [ "interface-name:${cfg.interface}" ];

        environment.systemPackages = [ pkgs.wireguard-tools ];
      };
    };
}
