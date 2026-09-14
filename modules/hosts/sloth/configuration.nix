{ self, inputs, ... }: {
  flake.nixosModules.slothConfiguration = { pkgs, lib, ... }: {
    imports = with self.nixosModules; [
      inputs.sops-nix.nixosModules.sops
      sops

      slothHardware
      framework16
      bootGrubZfs
      networkingDefault
      locale
      time
      fonts
      audio

      shareSmbClient
      shareSmb

      yubikey
      neovim

      plasma
      games

      mainUser
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.sharedModules = with self.homeModules; [
          yubikey
        ];
        home-manager.users.main = self.homeModules.main;
      }
    ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixpkgs.config.allowUnfree = true;

    services.zfs.trim = {
      enable = true;
      interval = "monthly";
    };

    services.zfs.autoScrub = {
      enable = true;
      interval = "monthly";
    };

    networking.hostName = "sloth";
    # hostId derived from systemd machine-id; head -c 8 /etc/machine-id
    networking.hostId = "e74cb8bd";

    environment.systemPackages = with pkgs; [
      vim
      wget
      git
      gnupg
    ];

    system.stateVersion = "26.05";

  };
}
