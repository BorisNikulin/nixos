{ self, inputs, ... }: {
  flake.nixosModules.flaresolverr = { pkgs, lib, ... }: {
    config = {
      services.flaresolverr.enable = true;
    };
  };
}
