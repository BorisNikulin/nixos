{ self, inputs, ... }: {
  flake.nixosModules.plasma = { pkgs, lib, ... }: {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    services.desktopManager.plasma6.enable = true;

    # Enable experimental running of electron/chromium apps natively in wayland.
    # Avoids scaling issues of xwayland.
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
