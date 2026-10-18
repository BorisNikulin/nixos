{ self, inputs, ... }: {
  flake.nixosModules.monitoring =
    { pkgs, lib, ... }:
    {
      imports = [
        self.nixosModules.prometheus
        self.nixosModules.grafana
      ];
    };
}
