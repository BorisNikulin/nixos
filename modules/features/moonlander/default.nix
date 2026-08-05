{ self, inputs, ... }: {
  flake.nixosModules.moonlander = { pkgs, ... }: {
    hardware.keyboard.zsa.enable = true;
    environment.systemPackages = with pkgs; [
      keymapp # GUI helper
    ];
  };
}
