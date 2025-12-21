{ config, lib, pkgs, ... }:
let
 cfg = config.networking.protonWireguard;
in
{
  options = {
    networking.protonWireguard = {
      qb = { 
        enable = lib.mkEnableOption "Create proton VPN wireguard interface";

        privateKeyFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to file containing private wireguard key";
        };
      };
    };
  };

  config = lib.mkIf cfg.qb.enable {
    networking.firewall = {
      allowedUDPPorts = [ 51820 ];
    };

    networking.wg-quick = {
      interfaces = {
        wg-qb = {
          autostart = true;
          dns = [ "10.2.0.1" ];
          privateKeyFile = cfg.qb.privateKeyFile;
          # match firewall allowdUDPorts; otherwise uses random port
          listenPort = 51820;
          address = [ "10.2.0.2/32" ];
          peers = [
            {
              publicKey = "MkUR6S5ObCzMx0ZToukggFecdUEjEM2GU/ZhLoz2ICY=";
              allowedIPs = [ "0.0.0.0/0" "::/6" ];
              # allowedIPs = [];
              endpoint = "149.102.254.65:51820";
              # Keep NAT tables alive
              persistentKeepalive = 30;
            }
          ];
        };
      };
    };
  };
}
