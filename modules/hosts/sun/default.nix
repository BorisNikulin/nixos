{ self, inputs, ... }: {
  # NAS
  # Intel Xeon E3-1280 v3 (8 threads) @ 3.60 GHz
  # 32 GiB 1600 MT/s DDR3 ECC
  flake.nixosConfigurations.sun = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.sunConfiguration
    ];
  };
}
