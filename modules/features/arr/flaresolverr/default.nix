{ self, inputs, ... }: {
  flake.nixosModules.flaresolverr = { ... }: {
    config = {
      services.flaresolverr.enable = true;
    };
  };
}
