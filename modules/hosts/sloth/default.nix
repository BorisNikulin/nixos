{ self, inputs, ... }: {
  # Framework 16 laptop
  # Ryzen 7840HS with 780M radeon iGPU
  # 32GiB 5600 MT/s
  flake.nixosConfigurations.sloth = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.slothConfiguration
    ];
  };
}
