{ self, inputs, ... }: {
  flake.nixosModules.slothConfiguration = { pkgs, lib, ... }: {
    imports = [
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.sops

      self.nixosModules.slothHardware
      self.nixosModules.framework16
      self.nixosModules.bootGrubZfs
      self.nixosModules.networkingDefault
      self.nixosModules.locale
      self.nixosModules.time
      self.nixosModules.fonts
      self.nixosModules.audio

      self.nixosModules.yubikey
      self.nixosModules.neovim

      self.nixosModules.plasma
      self.nixosModules.games

      self.nixosModules.mainUser
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.sharedModules = [
          self.homeModules.yubikey
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
