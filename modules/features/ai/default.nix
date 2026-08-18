{ self, inputs, ... }: {
  flake.nixosModules.localAi =
    { pkgs, lib, ... }:
    {
      imports = with self.nixosModules; [
        llamaCpp
      ];
    };
}
