{ self, inputs, ... }: {
  flake.nixosModules.auth =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.auth;
    in
    {
      imports = [
        self.nixosModules.lldap
        self.nixosModules.authelia
      ];

      options.auth = {
        apps = lib.mkOption {
          default = { };
          description = "Apps behind Authelia, keyed by app name.";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                domain = lib.mkOption {
                  type = lib.types.str;
                  description = "The vhost domain; matched in the app's authelia access rule.";
                };
                policy = lib.mkOption {
                  type = lib.types.str;
                  default = "one_factor";
                  description = ''
                    Authelia access policy (bypass, one_factor, two_factor, deny).
                    one_factor is the default: a passkey logs in as a first factor on
                    its own, and second factors stay available in the profile without
                    being forced on every app login.
                  '';
                };
                groups = lib.mkOption {
                  description = "The LLDAP groups that gate access to this app.";
                  type = lib.types.submodule {
                    options = {
                      view = lib.mkOption {
                        default = null;
                        type = lib.types.nullOr lib.types.str;
                        description = "Group granted read/view access; omit when the app has no read tier.";
                      };
                      admin = lib.mkOption {
                        default = null;
                        type = lib.types.nullOr lib.types.str;
                        description = "Group granted write/admin access; omit when the app has no admin tier.";
                      };
                    };
                  };
                };
              };
            }
          );
        };

        forwardAuth = {
          upstream = lib.mkOption {
            default = "127.0.0.1:9091";
            type = lib.types.str;
            description = "Host:port Authelia listens on; shared between the authelia instance and caddyForwardAuth.";
          };
          caddyForwardAuth = lib.mkOption {
            description = "Caddy snippet protecting a vhost with Authelia forward-auth. The app behind it must accept the copied headers and only be reachable from caddy.";
            type = lib.types.functionTo lib.types.str;
          };
        };
      };

      config = {
        auth.forwardAuth.caddyForwardAuth =
          {
            copy_headers ? [
              "Remote-User"
              "Remote-Groups"
              "Remote-Email"
              "Remote-Name"
            ],
            upstream ? cfg.forwardAuth.upstream,
          }:
          ''
            forward_auth ${upstream} {
              uri /api/authz/forward-auth
              copy_headers ${lib.concatStringsSep " " copy_headers}
            }
          '';

        # App groups from the registry are part of the lldap bootstrap, so each
        # app's view/admin groups exist without every host restating them.
        services.lldap.bootstrap.groups =
          let
            allGroups = lib.concatLists (
              lib.mapAttrsToList (
                _: app:
                (lib.filter (g: g != null) [
                  app.groups.view
                  app.groups.admin
                ])
              ) cfg.apps
            );
          in
          lib.listToAttrs (lib.map (g: lib.nameValuePair g { }) (lib.unique allGroups));
      };
    };
}
