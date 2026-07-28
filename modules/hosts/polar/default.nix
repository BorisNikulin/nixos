{ self, inputs, ... }: {
  # Desktop
  # Ryzen 7800X3D
  # 7900XTX
  # 32GiB 6000 MT/s CL 30
  flake.nixosConfigurations.polar = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.polarConfiguration
    ];
  };
}
