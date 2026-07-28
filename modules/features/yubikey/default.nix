{ self, inputs, ... }: {
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  flake.nixosModules.yubikey = { pkgs, lib, ... }: {
    services.udev.packages = [ pkgs.yubikey-personalization ];

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    services.pcscd.enable = true;

    environment.systemPackages = with pkgs; [
      gnupg
    ];
  };

  flake.homeModules.yubikey = { pkgs, ... }: {
    home.packages = with pkgs; [
      yubikey-personalization
      yubikey-manager
      yubioath-flutter
    ];
  };
}
