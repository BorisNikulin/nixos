{ self, inputs, ... }: {
  flake.nixosModules.qbittorrent =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.qbittorrent;
    in
    {
      imports = [ self.nixosModules.vpnProtonQb ];

      options.qbittorrent = {
        profileDir = lib.mkOption {
          default = config.disko.devices.zpool.fast.datasets."encrypted/app/qbittorrent".options.mountpoint;
          type = lib.types.str;
          description = "Profile directory (--profile) holding qBittorrent state.";
        };
        downloadsSavePath = lib.mkOption {
          default =
            config.disko.devices.zpool.fast.datasets."encrypted/download".options.mountpoint + "/qbittorrent";
          type = lib.types.str;
          description = "Default download save path.";
        };
        webuiPort = lib.mkOption {
          default = 8181;
          type = lib.types.port;
          description = "WebUI listen port.";
        };
        interface = lib.mkOption {
          default = config.vpnProtonQb.interface;
          type = lib.types.str;
          description = "Interface for BT traffic.";
        };
      };

      config = {
        services.qbittorrent = {
          enable = true;
          profileDir = cfg.profileDir;
          group = "media";
          webuiPort = cfg.webuiPort;
          # TODO? LAN-only for now; caddy exposure TBD, pending authelia/lldap auth
          openFirewall = true;
          serverConfig = {
            LegalNotice.Accepted = true;
            BitTorrent.Session = {
              Interface = cfg.interface;
              # 0 = Allow, 1 = Require, 2 = Disable.
              Encryption = 1;
              AnonymousModeEnabled = true;

              DefaultSavePath = cfg.downloadsSavePath;

              QueueingSystemEnabled = true;
              MaxActiveDownloads = 20;
              MaxActiveUploads = 10;
              MaxActiveTorrents = 100;
              IgnoreSlowTorrentsForQueueing = true;
              SlowTorrentsUploadRate = 50; # KiB/s
              SlowTorrentsDownloadRate = 50; # KiB/s

              GlobalMaxRatio = 3.0;
              GlobalMaxSeedingMinutes = 129600; # 3 months
              # When global limits hit, remove but keep files.
              ShareLimitAction = "Remove";
            };
            Preferences = {
              General = {
                StatusbarExternalIPDisplayed = true;
              };
              WebUI = {
                Username = "skimming9138";
                Password_PBKDF2 = "@ByteArray(w3q9jb7VMR+qJ2xTmC+e/g==:hXu3zqQVCkjqPANqG8YJOctX9l/JNqkXpk1bcozmq6/xd2je0IQ2FlTEknbAUikbOvHl6miyvUpSEOaQtabH/Q==)";
              };
            };
          };
        };
      };
    };
}
