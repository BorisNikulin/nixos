{ self, inputs, ... }: {
  flake.nixosModules.polarConfiguration = { pkgs, lib, ... }: {
    imports = with self.nixosModules; [
      inputs.sops-nix.nixosModules.sops
      sops

      polarHardware
      bootDefault
      networkingDefault
      locale
      time
      fonts
      audio

      yubikey
      neovim

      # plasma
      niri

      games

      mainUser
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

    networking.hostName = "polar";
    # hostId derived from systemd machine-id; head -c 8 /etc/machine-id
    networking.hostId = "9111466e";

    programs.zsh.enable = true;

    environment.systemPackages = with pkgs; [
      vim
      wget
      git
      btop-rocm
    ];

    system.stateVersion = "26.05";
  };
}
