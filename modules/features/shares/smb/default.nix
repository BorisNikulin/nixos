{ self, inputs, ... }: {
  flake.nixosModules.shareSmbServer =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      #TODO: figure out the user situation; enrollment is currently
      # imperative (add each unix user to samba manually).
      services.samba = {
        enable = true;
        openFirewall = true;
        settings = {
          global = {
            "server string" = config.networking.hostName;
            "hosts allow" = "10.0.0.0/8";
            "map to guest" = "bad user";
            # Map ':' to '÷' in CIFS names so ZFS snapshot names stay usable.
            # Samba's default mangling would render them as unreadable 8.3-style names over SMB.
            "vfs objects" = "catia";
            "catia:mappings" = "0x3a:0xf7";
          };
          "share" = {
            "path" = config.disko.devices.zpool.fast.datasets."encrypted/share".options.mountpoint;
            "read only" = "no";
          };
          "media" = {
            "path" = config.disko.devices.zpool.main.datasets.media.options.mountpoint;
            "force group" = "media";
            "read only" = "no";
          };
        };
      };
    };

  # Base for the SMB client: renders services.smbClient.shares into CIFS
  # automounts. Hosts import this once, plus the per-share modules
  # (shareSmb, shareSmbMedia) which append to `shares`. Importing a module
  # twice is an error, so the share modules don't import the base.
  flake.nixosModules.shareSmbClient =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.smbClient;
    in
    {
      options.services.smbClient = {
        server = lib.mkOption {
          default = "10.0.0.7";
          type = lib.types.str;
          description = "LAN address of the SMB server (sun).";
        };
        credentialsFile = lib.mkOption {
          default = config.sops.secrets."share/smb".path;
          type = lib.types.path;
          description = "cifs credentials file (username= / password=).";
        };
        shares = lib.mkOption {
          default = [ ];
          type = lib.types.listOf lib.types.str;
          description = "SMB shares to mount, each at /mnt/<share>; entries from multiple modules are concatenated.";
        };
      };

      config.fileSystems = lib.listToAttrs (
        lib.map (
          s:
          lib.nameValuePair "/mnt/${s}" {
            device = "//${cfg.server}/${s}";
            fsType = "cifs";
            options = [
              "x-systemd.automount"
              "x-systemd.device-timeout=5s"
              "x-systemd.mount-timeout=5s"
              "nofail"

              "credentials=${cfg.credentialsFile}"
              "users"
              "uid=1000"
              "gid=100"
            ];
          }
        ) cfg.shares
      );
    };

  flake.nixosModules.shareSmb = { pkgs, lib, ... }: {
    services.smbClient.shares = [ "share" ];
  };

  flake.nixosModules.shareSmbMedia = { pkgs, lib, ... }: {
    services.smbClient.shares = [ "media" ];
  };
}
