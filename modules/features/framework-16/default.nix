{ self, inputs, ... }: {
  flake.nixosModules.framework16 = { pkgs, lib, ... }: {
    imports = [
      inputs.nixos-hardware.nixosModules.framework-16-7040-amd
    ];

    hardware.inputmodule.enable = true;

    environment.systemPackages = with pkgs; [
      framework-tool
    ];
  };
}
