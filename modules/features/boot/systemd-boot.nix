{ self, inputs, ... }: {
  flake.nixosModules.bootSystemd = { pkgs, lib, ... }: {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

  };
}
