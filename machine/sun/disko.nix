{
  config,
  lib,
  pkgs,
  ...
}:
{
  disko.devices =
    let
      mkZfsFastDisk = device: {
        type = "disk";
        inherit device;
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
      mkZfsMainDisk = device: {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            swap = {
              # 2GiB
              start = "128";
              end = "4194304";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            zfs = {
              # 18TB - 2GiB = 16.4TiB
              start = "4194432";
              end = "35156656094";
              content = {
                type = "zfs";
                pool = "main";
              };
            };
          };
        };
      };
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
                mountpoint = "none";
                canmount = "off";
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
            "encrypted/key" = {
              type = "zfs_fs";
              mountpoint = "/etc/zfs/key";
              options = {
                copies = "2";
              };
            };
          };
        };

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
                mountpoint = "none";
                canmount = "off";
                encryption = "aes-256-gcm";
                keyformat = "hex";
                keylocation = "file:///etc/zfs/key/fast/encrypted.hex";
                # Use to bootstrap initial creation during install when root does not exist
                # keyformat = "passphrase";
                # keylocation = "prompt";
              };
            };
            "encrypted/share" = {
              type = "zfs_fs";
              mountpoint = "/mnt/fast/share";
              options = {
                atime = "on";
              };
            };
            "encrypted/app" = {
              type = "zfs_fs";
              mountpoint = "/mnt/fast/app";
            };
            "encrypted/app/prometheus" = {
              type = "zfs_fs";
              mountpoint = "/var/lib/" + config.services.prometheus.stateDir;
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
                mountpoint = "none";
                canmount = "off";
                encryption = "aes-256-gcm";
                keyformat = "hex";
                keylocation = "file:///etc/zfs/key/main/encrypted.hex";
                # Use to bootstrap initial creation during install when root does not exist
                # keyformat = "passphrase";
                # keylocation = "prompt";
              };
            };
            "encrypted/share" = {
              type = "zfs_fs";
              mountpoint = "/mnt/main/share";
              options = {
                atime = "on";
              };
            };
            "encrypted/share/public" = {
              type = "zfs_fs";
              mountpoint = "/mnt/main/share2/public";
            };
            "encrypted/share/public-write" = {
              type = "zfs_fs";
              mountpoint = "/mnt/main/share2/public-write";
              options = {
                refquota = "1T";
              };
            };
            share = {
              type = "zfs_fs";
              mountpoint = "/mnt/main/share-bak";
              options = {
                casesensitivity = "insensitive";
                acltype = "nfsv4";
                aclmode = "restricted";
                atime = "on";
              };
            };
            "share/public" = {
              type = "zfs_fs";
              mountpoint = "/mnt/main/share-bak/public";
            };
            "share/public-write" = {
              type = "zfs_fs";
              mountpoint = "/mnt/main/share-bak/public-write";
              options = {
                refquota = "1T";
              };
            };
            media = {
              type = "zfs_fs";
              mountpoint = "/mnt/main/media";
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
