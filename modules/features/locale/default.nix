{ self, inputs, ... }: {
  flake.nixosModules.locale = { ... }: {
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
