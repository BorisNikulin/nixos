{
  description = "Personal NixOS configs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      disko,
      sops-nix,
      home-manager,
      nvf,
    }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      # NAS
      nixosConfigurations.sun = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          sops-nix.nixosModules.sops
          ./sops.nix

          disko.nixosModules.disko
          ./machine/sun/disko.nix

          ./machine/sun/configuration.nix

          ./nixosModules/postfix
          ./nixosModules/servarr
          ./nixosModules/protonVpn
        ];
      };

      # Framework 16 laptop
      # Ryzen 7840HS with 780M radeon iGPU
      # 32GiB 5600 MT/s
      nixosConfigurations.sloth = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-hardware.nixosModules.framework-16-7040-amd
          sops-nix.nixosModules.sops
          ./sops.nix

          # TODO: move to standalone
          nvf.nixosModules.default
          ./nvf.nix

          ./machine/sloth/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.main = import ./machine/sloth/home.nix;
          }
        ];
      };

      formatter.x86_64-linux = pkgs.nixfmt-rfc-style;
    };
}
