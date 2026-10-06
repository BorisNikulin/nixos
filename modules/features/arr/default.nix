{ self, inputs, ... }: {
  flake.nixosModules.arr =
    { ... }:
    {
      imports = [
        self.nixosModules.qbittorrent
        self.nixosModules.prowlarr
        self.nixosModules.radarr
        self.nixosModules.sonarr
        self.nixosModules.flaresolverr
        self.nixosModules.recyclarr
      ];
    };
}
