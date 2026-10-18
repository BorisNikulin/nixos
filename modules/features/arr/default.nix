{ self, inputs, ... }: {
  flake.nixosModules.arr =
    { pkgs, lib, ... }:
    {
      imports = with self.nixosModules; [
        qbittorrent
        prowlarr
        radarr
        sonarr
        flaresolverr
        recyclarr
      ];
    };
}
