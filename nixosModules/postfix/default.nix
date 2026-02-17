{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.postfixRootToGmail;
in
{
  options.services.postfixRootToGmail = {
    enable = lib.mkEnableOption "Setup Postfix service and route root to chosen gmail";
    smtpSaslPasswordMap = lib.mkOption {
      type = lib.types.path;
      example = ''\${config.sops.secrets."postfix/sasl_password_map".path}'';
      description = "Postifx file to a password texthash map like '[smtp.gmail.com]:587 you@gmail.com:abcdefghjklmnopq'";
    };
    virtualAliasMap = lib.mkOption {
      type = lib.types.path;
      example = ''\${config.sops.secrets."postfix/virtual_alias_map".path}'';
      description = "Postifx file to a virtual alias texthash map like 'root example@google.com'";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postfix = {
      enable = true;
      settings.main = {
        relayhost = [ "[smtp.gmail.com]:587" ];
        smtp_use_tls = "yes";
        smtp_sasl_auth_enable = "yes";
        smtp_sasl_security_options = "";
        smtp_sasl_password_maps = "texthash:${cfg.smtpSaslPasswordMap}";
        # optional: Forward mails to root (e.g. from cron jobs, smartd)
        # to me privately and to my work email:
        virtual_alias_maps = "texthash:${cfg.virtualAliasMap}";
      };
    };
  };
}
