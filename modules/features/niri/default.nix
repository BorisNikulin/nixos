{ self, inputs, moduleWithSystem, ... }: {
  imports = [
    inputs.wrappers.flakeModules.wrapper
  ];

  flake.nixosModules.niri = moduleWithSystem ({ self', inputs', ...}:
  {pkgs, lib, config, ... }: {
  });

  perSystem = { self', inputs', ... }: {
    
  };
}
