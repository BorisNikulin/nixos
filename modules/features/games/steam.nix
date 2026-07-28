{ self, inputs, ... }: {
  flake.nixosModules.steam = { pkgs, lib, ... }: {
    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };
}
