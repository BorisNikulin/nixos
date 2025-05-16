{ config, lib, pkgs, ... } :
{
  disko.devices = let
    mkZfsDisk = pool: device: {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                inherit pool;
              };
            };
          };
        };
    };
    mkZfsFastDisk = mkZfsDisk "fast";
    mkZfsMainDisk = mkZfsDisk "main";
  in
  {
    disk = {
      # Crucial MX500 500G
      crucialMx500500g1 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x500a0751e88f3a5a";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "nofail" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };

      # Samsung 990 Pro 4T
      samsung990Pro4t1 = mkZfsFastDisk "/dev/disk/by-id/nvme-eui.002538414144adbf";
      samsung990Pro4t2 = mkZfsFastDisk "/dev/disk/by-id/nvme-eui.002538414144ae76";

      # Ironwolf pro 18T
      ironwolfPro18t1 = mkZfsMainDisk "/dev/disk/by-id/wwn-0x5000c500e5bd498e";
      ironwolfPro18t2 = mkZfsMainDisk "/dev/disk/by-id/wwn-0x5000c500e45ff430";
      ironwolfPro18t3 = mkZfsMainDisk "/dev/disk/by-id/wwn-0x5000c500e5ace6c3";
      ironwolfPro18t4 = mkZfsMainDisk "/dev/disk/by-id/wwn-0x5000c500e5f75a6c";
      ironwolfPro18t5 = mkZfsMainDisk "/dev/disk/by-id/wwn-0x5000c500e5bc90ab";

    };
    zpool = {
      zroot = {
        type = "zpool";
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                members = [ "crucialMx500500g1" ];
              }
            ];
          };
        };
        options = {
          # Workaround: cannot import 'zroot': I/O error in disko tests
          cachefile = "none";
          ashift = "12";
        };
        rootFsOptions = {
          canmount = "off";
          mountpoint = "none";
          compression = "lz4";
          acltype = "posixacl";
          xattr = "sa";
          atime = "off";
        };
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot@blank$' || zfs snapshot zroot@blank";
        datasets = {
          encrypted = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "prompt";
            };
          };
          "encrypted/root" = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "encrypted/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              compression = "zstd";
            };
          };
        };
      };
      # };

      fast = {
        type = "zpool";
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                mode = "mirror";
                members = [
                  "samsung990Pro4t1"
                  "samsung990Pro4t2"
                ];
              }
            ];
          };
        };
        options = {
          ashift = "12";
        };
        rootFsOptions = {
          canmount = "off";
          mountpoint = "none";
          atime = "off";
          xattr = "sa";
          compression = "lz4";
        };
        datasets = {
          encrypted = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              encryption = "aes-256-gcm";
              keyformat = "hex";
              keylocation = "file:///etc/zfs/key/fast/encrypted.hex";
              # Use to bootstrap initial creation during install when root does not exist
              # keyformat = "passphrase";
              # keylocation = "prompt";
            };
          };
          "encrypted/prometheus" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/var/lib/" + config.services.prometheus.stateDir;
            };
          };
          game = {
            type = "zfs_volume";
            size = "1T";
            options = {
              volblocksize = "128K";
            };
            # content = {
            #   type = "filesystem";
            #   format = "ntfs";
            # };
          };
        };
      };
      
      main = {
        type = "zpool";
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                mode = "raidz2";
                members = [
                  "ironwolfPro18t1"
                  "ironwolfPro18t2"
                  "ironwolfPro18t3"
                  "ironwolfPro18t4"
                  "ironwolfPro18t5"
                ];
              }
            ];
          };
        };
        options = {
          ashift = "12";
        };
        rootFsOptions = {
          canmount = "off";
          mountpoint = "none";
          atime = "off";
          xattr = "sa";
          compression = "zstd";
        };
        datasets = {
          encrypted = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              encryption = "aes-256-gcm";
              keyformat = "hex";
              keylocation = "file:///etc/zfs/key/main/encrypted.hex";
              # Use to bootstrap initial creation during install when root does not exist
              # keyformat = "passphrase";
              # keylocation = "prompt";
            };
          };
          share = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/main/share";
              canmount = "on";
              casesensitiveity = "insensitive";
              acltype = "nfsv4";
              aclmode = "restricted";
            };
          };
          "share/public" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/main/share/public";
              canmount = "on";
            };
          };
          "share/public-write" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/main/share/public";
              canmount = "on";
              refquota = "1T";
            };
          };
          media = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/main/media";
              canmount = "on";
              acltype = "posix";
            };
          };
        };
      };
    };
  };

  boot.zfs.extraPools = [
    "fast"
    "main"
  ];
}
