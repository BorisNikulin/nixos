{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  perSystem = { pkgs, ... }: {
    packages.lldap-bootstrap = pkgs.callPackage ./_package.nix { };
  };

  flake.nixosModules.lldap = moduleWithSystem (
    {
      self',
      ...
    }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.lldap;
      userJson = id: attrs: builtins.toJSON (attrs // { inherit id; });
      groupJson = name: attrs: builtins.toJSON (attrs // { inherit name; });
      configFiles =
        (lib.mapAttrs' (
          id: attrs: lib.nameValuePair "users/${id}.json" (userJson id attrs)
        ) cfg.bootstrap.users)
        // (lib.mapAttrs' (
          name: attrs: lib.nameValuePair "groups/${name}.json" (groupJson name attrs)
        ) cfg.bootstrap.groups);
      configs = pkgs.symlinkJoin {
        name = "lldap-bootstrap-configs";
        paths = lib.mapAttrsToList (
          path: text:
          pkgs.writeTextFile {
            name = "lldap-cfg";
            destination = "/${path}";
            inherit text;
          }
        ) configFiles;
      };
    in
    {
      options.services.lldap.bootstrap = lib.mkOption {
        default = {
          users = { };
          groups = { };
        };
        description = "Declarative LLDAP users and groups, converged by the lldap-bootstrap service.";
        type = lib.types.submodule {
          options = {
            # Resolved against self'.packages because the converger is built
            # by this flake, not nixpkgs.
            package = lib.mkPackageOption self'.packages "lldap-bootstrap" {
              pkgsText = "self'.packages";
            };
            users = lib.mkOption {
              default = { };
              description = "Users to manage, keyed by lldap user id (the LDAP uid). Each value is dumped 1:1 to the user JSON bootstrap.sh reads, so option names match its fields exactly, and the id field is set from the key. See https://github.com/lldap/lldap/blob/main/example_configs/bootstrap/bootstrap.md#user-config-file-example for the schema.";
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    email = lib.mkOption {
                      type = lib.types.str;
                      description = "Unique email address (lldap requires one).";
                    };
                    displayName = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.str;
                      description = "Display name; lldap falls back to the uid when null.";
                    };
                    firstName = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.str;
                    };
                    lastName = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.str;
                    };
                    groups = lib.mkOption {
                      default = [ ];
                      type = lib.types.listOf lib.types.str;
                      description = "Names of the groups this user belongs to (see bootstrap.groups).";
                    };
                    avatar_file = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.path;
                      description = "Local image to upload as the avatar; ignored when avatar_url is set.";
                    };
                    avatar_url = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.str;
                      description = "URL to fetch as the avatar; overrides avatar_file.";
                    };
                    gravatar_avatar = lib.mkOption {
                      default = false;
                      type = lib.types.bool;
                      description = "Fetch the avatar from gravatar using the email.";
                    };
                    weserv_avatar = lib.mkOption {
                      default = false;
                      type = lib.types.bool;
                      description = "Route avatar_url through the wsrv.nl image proxy.";
                    };
                    password = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.str;
                      description = "Plain password; the value ends up in the nix store, so test accounts only. Prefer password_file.";
                    };
                    password_file = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.path;
                      description = "File containing the user's password (trailing newline ignored); only applied while the existing hash differs.";
                    };
                  };
                }
              );
            };
            groups = lib.mkOption {
              default = { };
              description = "Groups to manage, keyed by group display name. Each value is dumped 1:1 to the group JSON bootstrap.sh reads, with the name field set from the key. See https://github.com/lldap/lldap/blob/main/example_configs/bootstrap/bootstrap.md#group-config-file-example for the schema.";
              type = lib.types.attrsOf lib.types.attrs;
            };
          };
        };
      };

      config = {
        services.lldap = {
          enable = true;
          settings = {
            ldap_base_dn = "dc=rhakotis,dc=xyz";
            ldap_user_dn = "admin";
            ldap_user_pass_file = config.sops.secrets."lldap/admin_pass".path;
            force_ldap_user_pass_reset = "always";
            http_host = "127.0.0.1";
            ldaps_options =
              let
                certDir = config.security.acme.certs."ldap.rhakotis.xyz".directory;
              in
              {
                enabled = true;
                port = 636;
                cert_file = "${certDir}/cert.pem";
                key_file = "${certDir}/key.pem";
              };
          };
        };
        # Allow binding to ports < 1024 (ldaps on 636)
        systemd.services.lldap.serviceConfig = {
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        };

        users.users.lldap = {
          description = "lldap server user";
          isSystemUser = true;
          group = "lldap";
        };
        users.groups.lldap = { };

        services.caddy.virtualHosts."lldap.${config.domain}" = {
          useACMEHost = config.certs.wildcard.acmeHost;
          extraConfig = ''
            reverse_proxy ${cfg.settings.http_host}:${toString cfg.settings.http_port}
          '';
        };

        systemd.services.lldap-bootstrap = {
          description = "Converge LLDAP users and groups from Nix-managed configuration";
          wantedBy = [ "multi-user.target" ];
          after = [ "lldap.service" ];
          wants = [ "lldap.service" ];
          serviceConfig.EnvironmentFile = [
            (pkgs.writeText "lldap-bootstrap.env" ''
              LLDAP_URL=http://${cfg.settings.http_host}:${toString cfg.settings.http_port}
              LLDAP_ADMIN_USERNAME=admin
              LLDAP_ADMIN_PASSWORD_FILE=${config.sops.secrets."lldap/admin_pass".path}
              USER_CONFIGS_DIR=${configs}/users
              GROUP_CONFIGS_DIR=${configs}/groups
              # Note there is per config type cleanup
              # which can be desirable if you do not want to delete manually added users.
              # This enables cleanup (deletion) of all types such as users, groups, and user group inclusion.
              DO_CLEANUP=true
            '')
          ];
          script = ''
            ${lib.getExe cfg.bootstrap.package}
          '';
        };
      };
    }
  );
}
