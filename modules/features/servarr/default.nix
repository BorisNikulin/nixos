{
  flake.nixosModules.servarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.servarr;

      config.services.servarr.openFirewall = lib.mkDefault true;
      config.services.servarr.group = lib.mkDefault "media";
      # TODO: set in disko module
      config.services.servarr.parentDataDir = lib.mkDefault "/mnt/fast/app";
    in
    {
      options = {
        services.servarr = {
          group = lib.mkOption {
            type = lib.types.str;
            default = "radarr";
            description = "Group under which Radarr runs.";
          };

          parentDataDir = lib.mkOption {
            type = lib.types.path;
            description = "The parent directory under which the servarr apps will create their own directories";
          };

          # TODO: setup authelia + lldap with caddy reverse proxy
          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Open ports in the firewall for the Radarr web interface.";
          };
        };
      };

      config = {
        services = {
          prowlarr = {
            enable = true;
            openFirewall = cfg.openFirewall;
          };

          flaresolverr = {
            enable = true;
          };

          radarr = {
            enable = true;
            openFirewall = cfg.openFirewall;
            group = cfg.group;
            dataDir = "${cfg.parentDataDir}/radarr/.config/Radarr";
          };

          sonarr = {
            enable = true;
            openFirewall = cfg.openFirewall;
            group = cfg.group;
            dataDir = "${cfg.parentDataDir}/sonarr/.config/NzbDrone";
          };
        };
      };
    };
}
