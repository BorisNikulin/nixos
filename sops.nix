{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "boris/passwordHash" = {
        neededForUsers = true;
      };
      "share" = { };
      "postfix/sasl_password_map" = lib.mkIf config.services.postfix.enable {
        owner = config.services.postfix.user;
        restartUnits = [ config.systemd.services.postfix.name ];
      };
      "postfix/virtual_alias_map" = lib.mkIf config.services.postfix.enable {
        owner = config.services.postfix.user;
        restartUnits = [ config.systemd.services.postfix.name ];
      };
      "proton/qb" = # lib.mkIf config.networking.protonWireguard.qb.enable
        {
        };
      "cloudflare/dns_api_token" = lib.mkIf config.security.acme.acceptTerms {
      };
    };
  };
}
