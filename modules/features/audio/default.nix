{ self, inputs, ... }: {
  flake.nixosModules.audio = { pkgs, lib, ... }: {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
