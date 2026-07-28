{ self, inputs, ... }: {
  flake.nixosModules.networkingDefault = { pkgs, lib, ... }: {
    networking.nftables.enable = true;
    networking.networkmanager.enable = true;
  };
}
