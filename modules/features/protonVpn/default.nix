{ self, inputs, ... }: {
  flake.nixosModules.protonWireguardQb =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      privateKeyFile = config.sops.secrets."proton/qb".path;
    in
    {
      #TODO: Try systemd networking with no routing table
      # since all other methods add routes and take over networking.
      # Here we just want a new interface and qb will bind to it directly
      # thus implicitly handling routing.

      networking.firewall = {
        allowedUDPPorts = [ 51820 ];
      };
      /*
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
      */
      /*
        networking.wireguard = {
          enable = true;
          interfaces = {
            wg0 = {
              ips = [ "10.2.0.2/32" ];
              listenPort = 51820;
              privateKeyFile = cfg.qb.privateKeyFile;

              peers = [
                {
                  name = "ProtonVPN";
                  publicKey = "MkUR6S5ObCzMx0ZToukggFecdUEjEM2GU/ZhLoz2ICY=";
                  allowedIPs = [
                    "0.0.0.0/0"
                    "::/6"
                  ];
                  endpoint = "149.102.254.65:51820";
                  persistentKeepalive = 30;
                }
              ];
            };
          };
        };
      */
    };
}
