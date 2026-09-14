{ self, inputs, ... }: {
  flake.nixosModules.shareSmbServer =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      #TODO: figure our user situation
      # curently it's imperative and requires manually enrolling a unix user to samba
      services.samba = {
        enable = true;
        openFirewall = true;
        settings = {
          global = {
            "workgroup" = "WORKGROUP";
            "server string" = config.networking.hostName;
            "netbios name" = config.networking.hostName;
            "security" = "user";
            # "use sendfile" = "yes";
            #"max protocol" = "smb2";
            # note: localhost is the ipv6 localhost ::1
            "hosts allow" = "10.0.0.0/8";
            # "hosts deny" = "0.0.0.0/0";
            "guest account" = "nobody";
            "map to guest" = "bad user";
          };
          "share" = {
            "path" = config.disko.devices.zpool.fast.datasets."encrypted/share".options.mountpoint;
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "no";
          };
          "media" = {
            "path" = config.disko.devices.zpool.main.datasets.media.options.mountpoint;
            "force group" = "media";
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "no";
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

      # An entry is either a plain share name (mounted at /mnt/<share>) or an
      # attrset to override the mount point when it differs from the share name.
      entry = lib.types.oneOf [
        lib.types.str
        (lib.types.submodule {
          options = {
            share = lib.mkOption {
              type = lib.types.str;
              description = "Name of the SMB share on the server.";
            };
            mountPoint = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Local mount point (default: /mnt/<share>).";
            };
          };
        })
      ];

      norm = e: if lib.isAttrs e then e else { share = e; };
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
          type = lib.types.listOf entry;
          description = "SMB shares to mount; entries from multiple modules are concatenated. An entry is a share name, or { share, ?mountPoint };";
        };
      };

      config.fileSystems = lib.listToAttrs (
        lib.map (
          e:
          let
            s = norm e;
            mountPoint = if s ? mountPoint && s.mountPoint != null then s.mountPoint else "/mnt/${s.share}";
          in
          lib.nameValuePair mountPoint {
            device = "//${cfg.server}/${s.share}";
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

  # One module per share: appends that share to services.smbClient.shares
  # (no enable option — importing the module is the enable).
  flake.nixosModules.shareSmb = { ... }: {
    services.smbClient.shares = [ "share" ];
  };

  flake.nixosModules.shareSmbMedia = { ... }: {
    services.smbClient.shares = [ "media" ];
  };
}
