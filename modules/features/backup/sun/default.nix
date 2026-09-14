{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.backupSun =
    {
      pkgs,
      lib,
      config,
      options,
      ...
    }:
    let
      customAppDatasets = [ "encrypted/app/continuwuity" ];
      datasetToApp = dataset: lib.last (lib.splitString "/" dataset);

      diskoAppDatasets = lib.filter (lib.hasPrefix "encrypted/app/") (
        lib.attrNames config.disko.devices.zpool.fast.datasets
      );
      basicAppDatasets = lib.lists.subtractLists customAppDatasets diskoAppDatasets;

      mkAppSanoidConfig =
        toTemplate: dataset:
        lib.nameValuePair "fast/${dataset}" {
          use_template = [ (toTemplate dataset) ];
        };

      mkDefaultAppSanoidConfig = mkAppSanoidConfig (lib.const "app");
      mkCustomAppSanoidConfig = mkAppSanoidConfig (dataset: "app-${datasetToApp dataset}");

      appDatasets =
        lib.listToAttrs (map mkDefaultAppSanoidConfig basicAppDatasets)
        // lib.listToAttrs (map mkCustomAppSanoidConfig customAppDatasets);

      c10yStopScript = pkgs.writeShellScript "sanoid-stop-c10y" ''
        ${pkgs.systemd}/bin/systemctl stop '${config.systemd.services.continuwuity.name}'
      '';
      c10yStartScript = pkgs.writeShellScript "sanoid-start-c10y" ''
        ${pkgs.systemd}/bin/systemctl start --no-block '${config.systemd.services.continuwuity.name}'
      '';
    in
    {
      services.sanoid = {
        enable = true;
        templates.app = {
          hourly = 72;
          daily = 14;
          weekly = 4;
          monthly = 1;
          yearly = 0;
          autoprune = true;
        };
        templates.app-continuwuity = {
          hourly = 0;
          daily = 14;
          weekly = 4;
          monthly = 1;
          yearly = 0;
          autoprune = true;
          # 5 am PDT (-7) / 4 am PST (-8)
          daily_hour = 12;
          daily_min = 0;
          # Offline backup used for seamless notouch restore.
          # Online is possible but needs an admin chat command and a restore procedure.
          # See https://continuwuity.org/maintenance.html#backups.
          # Note that permissions are required and added via polkit below.
          pre_snapshot_script = toString c10yStopScript;
          post_snapshot_script = toString c10yStartScript;
          script_timeout = 60 + (config.systemd.services.continuwuity.serviceConfig.TimeoutStopSec or 90);
        };
        templates.data = {
          hourly = 72;
          daily = 14;
          weekly = 8;
          monthly = 12;
          yearly = 0;
          autoprune = true;
        };
        templates.backupData = {
          hourly = 72;
          daily = 14;
          weekly = 8;
          monthly = 12;
          yearly = 0;
          autosnap = false;
          autoprune = true;
        };
        templates.backupApp = {
          hourly = 72;
          daily = 14;
          weekly = 4;
          monthly = 3;
          yearly = 0;
          autosnap = false;
          autoprune = true;
        };
        datasets = {
          "fast/encrypted/share" = {
            use_template = [ "data" ];
            recursive = true;
          };
          "main/media" = {
            use_template = [ "data" ];
          };
          "main/encrypted/backup/fast-share" = {
            use_template = [ "backupData" ];
            recursive = true;
          };
          "main/encrypted/backup/fast-app" = {
            use_template = [ "backupApp" ];
            recursive = true;
          };
          # Syncoid/zfs send require snapshots and child app datasets need target app parent to exist
          # so this provides the snapshots needed by syncoid to create that parent dataset for the app children.
          "fast/encrypted/app" = {
            use_template = [ "data" ];
          };
        }
        // appDatasets;
      };

      security.polkit = {
        enable = true;
        extraConfig = ''
          polkit.addRule(function(action, subject) {
              if (action.id === "org.freedesktop.systemd1.manage-units" &&
                  subject.system_unit === "${config.systemd.services.sanoid.name}" &&
                  action.lookup("unit") === "${config.systemd.services.continuwuity.name}" &&
                  (action.lookup("verb") === "start" ||
                   action.lookup("verb") === "stop")) {
                  return polkit.Result.YES;
              }
          });
        '';
      };

      services.syncoid = {
        enable = true;
        localSourceAllow = options.services.syncoid.localSourceAllow.default ++ [ "release" ];
        localTargetAllow = options.services.syncoid.localTargetAllow.default ++ [
          "hold"
          "release"
        ];
        # Local time zone.
        interval = [ "*-*-* 08:05:00" ];
        commonArgs = [
          # sanoid owns all source snapshots.
          "--no-sync-snap"
          # Hold newest source+target snap across runs (release next run).
          "--use-hold"
          # No --delete-target-snapshots as target snapshots are pruned
          # by the targets' own sanoid templates.
        ];
        commands = {
          share = {
            source = "fast/encrypted/share";
            target = "main/encrypted/backup/fast-share";
            recursive = true;
            # large blocks + compression
            sendOptions = "Lc";
          };
          app = {
            source = "fast/encrypted/app";
            target = "main/encrypted/backup/fast-app";
            recursive = true;
            sendOptions = "Lc";
          };
        };
      };
    };
}
