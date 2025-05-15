{ config, lib, pkgs, ... } :
{
  disko.devices = {
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

      # Samsung 990 Pro 4T x2
      samsung990Pro4t1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.002538414144adbf";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "fast";
              };
            };
          };
        };
      };
      samsung990Pro4t2 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.002538414144ae76";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "fast";
              };
            };
          };
        };
      };

      # Ironwolf pro 18T x5 already existing raidz2
      # ironwolfPro18t1 = {}; TODO

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
    };
  };
  # };

  # key for /nix needed for boot ultimately comes from the root dataset of fast
  # fileSystems."${disko.devices.zpool.fast.mountpoint}".depends = [ "/etc/zfs/keys" ];
  # fileSystems."/nix".depends = [ "/" ];
  # fileSystems."${disko.devices.zpool.fast.datasets.nix.mountpoint}".depends = [ "/" ];
  boot.zfs.extraPools = [
    "fast"
    "main"
  ];
}
