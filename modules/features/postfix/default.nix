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
}
