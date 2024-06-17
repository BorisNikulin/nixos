{
  description = "Framework 16 config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
  };

  outputs = { self, nixpkgs }: {
    # Framework 16 laptop
    # Ryzen 7840HS with 780M radeon iGPU
    # 32GiB 5600 MT/s
    nixosConfigurations.sloth = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ]; 
    };
  };
}
