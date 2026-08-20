{
  lib,
  ...
}:
{
  flake.nixosModules.sops = { config, ... }: {
    sops = {
      defaultSopsFile = ../secrets/secrets.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      secrets = {
        "boris/passwordHash" = {
          neededForUsers = true;
        };
        "share/smb" = { };
        "share/nvme-of/keyfile" = { };
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
        "grafana/secret_key" = lib.mkIf config.services.grafana.enable {
          owner = config.systemd.services.grafana.serviceConfig.User;
          restartUnits = [ config.systemd.services.grafana.name ];
        };
        "lldap/user_pass" = lib.mkIf config.services.lldap.enable {
          owner = config.systemd.services.lldap.serviceConfig.User;
          restartUnits = [ config.systemd.services.lldap.name ];
        };
      };
    };
  };
}
