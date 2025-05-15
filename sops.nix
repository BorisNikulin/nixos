{
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "share" = { };
      "postfix/sasl_password_map" = { };
      "postfix/virtual_alias_map" = { };
    };
  };
}
