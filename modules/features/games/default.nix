{ self, inputs, ... }: {
  flake.nixosModules.games = { pkgs, lib, ... }: {
    imports = [
      self.nixosModules.steam
    ];

    environment.sessionVariables.PROTON_ENABLE_WAYLAND = "1";
  };
}
