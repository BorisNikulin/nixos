{ self, inputs, ... }: {
  flake.nixosModules.postfix =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      smtpSaslPasswordMap = config.sops.secrets."postfix/sasl_password_map".path;
      virtualAliasMap = config.sops.secrets."postfix/virtual_alias_map".path;
    in
    {
      # Local SMTP port the MTA listens on.
      # For reference elsewhere.
      # Should match the port hardcoded in the nixos postfix module.
      options.postfix.smtpPort = lib.mkOption {
        type = lib.types.port;
        default = 25;
        readOnly = true;
        description = "Local SMTP port postfix listens on";
      };

      config = {
        services.postfix = {
          enable = true;
          settings.main = {
            relayhost = [ "[smtp.gmail.com]:587" ];
            smtp_use_tls = "yes";
            smtp_sasl_auth_enable = "yes";
            smtp_sasl_security_options = "";
            smtp_sasl_password_maps = "texthash:${smtpSaslPasswordMap}";
            # Forward mail to users like root to an email.
            # Used here for zfs/smartd notificaitons to root to forward to self email.
            virtual_alias_maps = "texthash:${virtualAliasMap}";
          };
        };
      };
    };
}
