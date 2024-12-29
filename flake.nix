{
  description = "Framework 16 config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, sops-nix, home-manager }: {
    # Framework 16 laptop
    # Ryzen 7840HS with 780M radeon iGPU
    # 32GiB 5600 MT/s
    nixosConfigurations.sloth = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.framework-16-7040-amd
        sops-nix.nixosModules.sops
        ./sops.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.main = import ./home.nix;
        }
      ];
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
  };
}
