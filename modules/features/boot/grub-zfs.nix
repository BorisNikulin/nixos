{ self, inputs, ... }: {
  flake.nixosModules.bootGrubZfs = { pkgs, lib, ... }: {
    # https://nixos.wiki/wiki/ZFS
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub = {
      enable = true;
      zfsSupport = true;
      efiSupport = true;
      mirroredBoots = [
        {
          devices = [ "nodev" ];
          path = "/boot";
        }
      ];
    };
  };
}
