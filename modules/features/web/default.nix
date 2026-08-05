{ self, inputs, ... }: {
  flake.nixosModules.domain = { pkgs, lib, ... }: {
    options = {
      domain = lib.mkOption {
        default = "rhakotis.xyz";
        type = lib.types.str;
        readOnly = true;
      };
    };
  };
}
