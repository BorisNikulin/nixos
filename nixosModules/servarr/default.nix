{ config, lib, pkgs, ...}:
let
  cfg = config.services.servarr;
in
{
  options = {
    services.servarr = {
      enable = lib.mkEnableOption "Setup servarr stack";

      group = lib.mkOption {
        type = lib.types.str;
        default = "radarr";
        description = "Group under which Radarr runs.";
      };

    parentDataDir = lib.mkOption {
        type = lib.types.path;
        description = "The parent directory under which the servarr apps will create their own directories";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open ports in the firewall for the Radarr web interface.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
}
