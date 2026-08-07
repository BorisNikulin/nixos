{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  flake.homeModules.calibre = moduleWithSystem (
    { self', pkgs, ... }:
    { lib, ... }: {
      programs.calibre = {
        enable = true;
      };

      # https://github.com/nydragon/calibre-plugins/blob/3f99ce55a85120a2408ec80284c6c14c4e701e0b/install.sh
      home.activation.calibrePluginsInstall = lib.hm.dag.entryAfter [ "installPackages" ] ''
        set -e

        installPlugin() {
            echo "Installing calibre plugin: $1"
            ${pkgs.calibre}/bin/calibre-customize -r "$2"
            ${pkgs.calibre}/bin/calibre-customize -a "$1"
        }

        installPlugin ${self'.packages.calibrePluginsAcsm} "ACSM Input"
        installPlugin ${self'.packages.calibrePluginsDeDrm} "DeDRM"
        installPlugin ${self'.packages.calibrePluginsObok} "Obok DeDRM"
      '';

    }
  );
}
