{
  lib,
  ...
}:
{
  flake.nixosModules.sops = { lib, config, ... }: {
    sops = {
      defaultSopsFile = ../secrets/secrets.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      secrets = {
        "boris/passwordHash" = {
          neededForUsers = true;
        };
        "share/smb" = { };
        "share/nvme-of/keyfile" = {
          restartUnits =
            lib.optionals (config.systemd.services ? nvmet) [
              config.systemd.services.nvmet.name
            ]
            ++ lib.optionals (config.systemd.services ? nvme-connect) [
              config.systemd.services.nvme-connect.name
            ];
        };
        "postfix/sasl_password_map" = lib.mkIf config.services.postfix.enable {
          owner = config.services.postfix.user;
          restartUnits = [ config.systemd.services.postfix.name ];
        };
        "postfix/virtual_alias_map" = lib.mkIf config.services.postfix.enable {
          owner = config.services.postfix.user;
          restartUnits = [ config.systemd.services.postfix.name ];
        };
        "proton/qb" = lib.mkIf config.systemd.network.enable {
          owner = "systemd-network";
        };
        "cloudflare/dns_api_token" = lib.mkIf config.security.acme.acceptTerms {
        };
        "grafana/secret_key" = lib.mkIf config.services.grafana.enable {
          owner = config.systemd.services.grafana.serviceConfig.User;
          restartUnits = [ config.systemd.services.grafana.name ];
        };
        "lldap/admin_pass" = lib.mkIf config.services.lldap.enable {
          owner = config.systemd.services.lldap.serviceConfig.User;
          restartUnits = [ config.systemd.services.lldap.name ];
        };
        "lldap/bind_pass/authelia" = lib.mkIf config.services.lldap.enable {
        };
        "lldap/user_pass/focu5" = lib.mkIf config.services.lldap.enable { };
        "authelia/ldap_bind_password" = lib.mkIf config.services.authelia.instances.main.enable {
          key = "lldap/bind_pass/authelia";
          owner = "authelia";
          restartUnits = [ "authelia.service" ];
        };
        "authelia/storage_key" = lib.mkIf config.services.authelia.instances.main.enable {
          owner = "authelia";
          restartUnits = [ "authelia.service" ];
        };
        "authelia/jwt_secret" = lib.mkIf config.services.authelia.instances.main.enable {
          owner = "authelia";
          restartUnits = [ "authelia.service" ];
        };
        "arr/prowlarr/api_key" = lib.mkIf config.services.prowlarr.enable {
        };
        "arr/radarr/api_key" = lib.mkIf config.services.recyclarr.enable {
          owner = config.services.recyclarr.user;
        };
        "arr/sonarr/api_key" = lib.mkIf config.services.recyclarr.enable {
          owner = config.services.recyclarr.user;
        };
      };
      templates = {
        "arr-prowlarr-api-key" = lib.mkIf config.services.prowlarr.enable {
          content = ''
            PROWLARR__AUTH__APIKEY=${config.sops.placeholder."arr/prowlarr/api_key"}
          '';
        };
        "arr-radarr-api-key" = lib.mkIf config.services.radarr.enable {
          content = ''
            RADARR__AUTH__APIKEY=${config.sops.placeholder."arr/radarr/api_key"}
          '';
        };
        "arr-sonarr-api-key" = lib.mkIf config.services.sonarr.enable {
          content = ''
            SONARR__AUTH__APIKEY=${config.sops.placeholder."arr/sonarr/api_key"}
          '';
        };
      };
    };
  };
}
