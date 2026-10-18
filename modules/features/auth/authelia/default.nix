{ self, inputs, ... }: {
  flake.nixosModules.authelia =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.auth.authelia;
      portal = "auth.${config.domain}";
      appRules = lib.mapAttrsToList (_: app: {
        domain = app.domain;
        policy = app.policy;
        subject = lib.map (g: "group:${g}") (
          lib.filter (g: g != null) [
            app.groups.view
            app.groups.admin
          ]
        );
      }) config.auth.apps;
    in
    {
      options.auth.authelia = {
        dataDir = lib.mkOption {
          type = lib.types.path;
          default = config.disko.devices.zpool.fast.datasets."encrypted/app/authelia".options.mountpoint;
          description = "Directory for the local sqlite session store and filesystem notifier.";
        };
      };

      config = {
        services.authelia.instances.main = {
          enable = true;
          # Sets user and group suffix or authelia if empty and our secrets use authelia owner.
          name = "";

          secrets = {
            jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
            storageEncryptionKeyFile = config.sops.secrets."authelia/storage_key".path;
          };

          settings = {
            log_level = "info";
            server = {
              address = "tcp://${config.auth.forwardAuth.upstream}";
            };
            theme = "auto";
            authentication_backend = {
              ldap = {
                implementation = "lldap";
                address = "ldaps://127.0.0.1:${toString config.services.lldap.settings.ldaps_options.port}";
                base_dn = "dc=rhakotis,dc=xyz";
                user = "uid=bind-authelia,ou=people,dc=rhakotis,dc=xyz";
                tls = {
                  server_name = "ldap.rhakotis.xyz";
                  minimum_version = "TLS1.2";
                };
              };
            };
            webauthn.enable_passkey_login = true;
            session = {
              cookies = [
                {
                  domain = config.domain;
                  authelia_url = "https://${portal}";
                }
              ];
            };
            storage = {
              local = {
                path = "${cfg.dataDir}/sessions.db";
              };
            };
            notifier = {
              disable_startup_check = true;
              smtp = {
                address = "smtp://127.0.0.1:${toString config.postfix.smtpPort}";
                disable_require_tls = true;
                # Required but overwritten by gmail via local postfix relay.
                sender = "auth@${config.domain}";
                subject = "[Rhakotis] {title}";
              };
            };
            access_control = {
              default_policy = "deny";
              rules = appRules;
            };
          };

          environmentVariables = {
            AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE =
              config.sops.secrets."authelia/ldap_bind_password".path;
          };
        };

        systemd.services.authelia.serviceConfig.ReadWritePaths = [ cfg.dataDir ];

        services.caddy.virtualHosts.${portal} = {
          useACMEHost = config.certs.wildcard.acmeHost;
          extraConfig = ''
            reverse_proxy ${config.auth.forwardAuth.upstream}
          '';
        };
      };
    };
}
