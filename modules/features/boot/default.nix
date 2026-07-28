{ self, inputs, ... }: {
  flake.nixosModules.bootDefault = self.nixosModules.bootSystemd;
}
