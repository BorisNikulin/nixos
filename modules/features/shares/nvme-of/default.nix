{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
let
  # Shared by the host and target `keyFile` options — both read the same sops
  # secret (`share/nvme-of/keyfile`) and the same NVMe/TCP TLS PSK keyfile.
  keyFileDescription = ''
    Path to an NVMe/TCP TLS PSK keyfile (the decrypted `share/nvme-of/keyfile`
    sops secret). Each line is 5 space-separated fields:
    `<ctrl-id> <host-nqn> <subsys-nqn> <secret> <psk>`.

    The psk MUST be a NVMe TCP 2.0 / v2 key — prefix `NVMeTLSkey-1`, NOT
    `NVMeTLSkey-0`. Keys generated with the default `-I 0`, or written directly
    with `nvme gen-tls-key --keyfile`, are derived/unusable and the import
    rejects them.

    Rotating the key (run on the target; both hosts consume the same file):

    Tooling: `nix run nixpkgs#nvme-cli` (nvme) and `nix run nixpkgs#keyutils`
    (keyctl). Every keyring step needs **sudo** and **tlshd running as a
    service** (the `.nvme` keyring only exists once tlshd is up).

    1. Generate a v2 key and insert it into the `.nvme` keyring:
       `sudo nvme gen-tls-key -I 1 -i -n <host-nqn> -c <subsys-nqn>`
    2. Validate it landed: `sudo keyctl list %:.nvme`
    3. Export it to a keyfile (only correct because a good v2 key is now in
       the keyring): `sudo nvme tls-key --export --keyfile <file>`
    4. Clear the keyring and confirm it is empty:
       `sudo keyctl clear %:.nvme && sudo keyctl list %:.nvme`
    5. Put the exported keyfile into `secrets/secrets.yaml` under
       `share/nvme-of/keyfile`, commit, and deploy to both hosts.
    6. Restart the consuming unit — `nvmet` (target) or `nvme-connect` (host) —
       which runs `nvme tls-key --import --keyfile` to (re)insert the key.
    7. Validate the new key is in: `sudo keyctl list %:.nvme`
  '';
in
{
  flake.nixosModules.shareGameNvmeOfHost =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = with self.nixosModules; [
        nvmeOfHost
      ];

      services.nvmeOf.host.config = [
        {
          hostnqn = "nqn.2014-08.org.nvmexpress:uuid:00000000-0000-0000-0000-3cecef8c225e";
          hostid = "34006b9c-5f54-0000-0000-000000000000";
          subsystems = [
            {
              nqn = "nqn.2026-08.xyz.rhakotis:game";
              ports = [
                {
                  transport = "tcp";
                  traddr = "10.0.0.7";
                  trsvcid = "4420";
                  tls = true;
                  # Prevents game stutters every 30 ish seconds to sub 30fps for 1 frame ish.
                  # 60s seemed to mostly resolve it.
                  keep_alive_tmo = 300;
                  reconnect_delay = 10;
                  # 2 days
                  # ctrl_loss_tmo = 172800;
                }
              ];
            }
          ];
        }
      ];

      fileSystems."/mnt/game" = {
        device = "/dev/disk/by-uuid/dbd5d94a-e526-4bbe-85b5-d9597060ebae";
        fsType = "ext4";
        options = [
          "x-systemd.requires=${config.systemd.services.nvme-connect.name}"

          "_netdev"
          "x-systemd.automount"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"

          "noatime"
        ];
      };
    };

  flake.nixosModules.shareGameNvmeOfTarget = moduleWithSystem (
    { self', pkgs, ... }:
    {
      lib,
      config,
      ...
    }:
    {
      imports = with self.nixosModules; [
        nvmeOfTarget
      ];

      services.nvmeOf.target = {
        # The one in nixpkgs is broken and v0.7 doesn't seem to work anyway.
        nvmetCliPackage = self'.packages.nvmet-cli;
        config = {
          hosts = [ ];
          ports = [
            {
              addr = {
                adrfam = "ipv4";
                traddr = "0.0.0.0";
                # require tls
                treq = "required";
                trsvcid = "4420";
                trtype = "tcp";
                tsas = "tls1.3";
              };
              ana_groups = [
                {
                  ana = {
                    state = "optimized";
                  };
                  grpid = 1;
                }
              ];
              param = {
                inline_data_size = "16384";
                max_queue_size = "1024";
                pi_enable = "0";
              };
              portid = 1;
              referrals = [ ];
              subsystems = [
                "nqn.2026-08.xyz.rhakotis:game"
              ];
            }
          ];
          subsystems = [
            {
              allowed_hosts = [ ];
              attr = {
                allow_any_host = "1";
                cntlid_max = "65519";
                cntlid_min = "1";
                model = "Linux";
                pi_enable = "0";
                qid_max = "128";
              };
              namespaces = [
                {
                  ana = {
                    grpid = "1";
                  };
                  ana_grpid = 1;
                  device = {
                    nguid = "00000000-0000-0000-0000-000000000000";
                    path = "/dev/zvol/fast/game";
                    uuid = "ffa2ef6c-d8c8-4ed9-af23-451bda18f0d8";
                  };
                  enable = 1;
                  nsid = 1;
                }
              ];
              nqn = "nqn.2026-08.xyz.rhakotis:game";
            }
          ];
        };
      };

    }
  );

  flake.nixosModules.nvmeOfTarget =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.nvmeOf.target;
      configFormat = pkgs.formats.json { };
      configFile = configFormat.generate "nvmet.json" cfg.config;
    in
    {
      imports = with self.nixosModules; [
        tlshd
      ];

      options = {
        services.nvmeOf.target = {
          # Note that the one in nixpkgs is broken (missing python dep six).
          # Also, version 0.7, the one in nixpkgs currently,  doesn't seem to work anyway.
          # There is a v0.8 that does from 2 years ago and, as a of few weeks ago,
          # there are commits to improve the tool (including removing six/python 2 deps).
          nvmetCliPackage = lib.mkOption {
            default = pkgs.nvmet-cli;
            type = lib.types.package;
          };
          nvmeCliPackage = lib.mkOption {
            default = pkgs.nvme-cli;
            type = lib.types.package;
          };
          keyFile = lib.mkOption {
            default = config.sops.secrets."share/nvme-of/keyfile".path;
            type = lib.types.path;
            description = keyFileDescription;
          };

          config = lib.mkOption {
            type = configFormat.type;
            description = ''
              Use `nvme connect/gen-tls-key/check-tls-key/tls-key` commands to connect and or setup tls keys.
              Then use `nvme --scan --dump` to see the json connection configs.
              Use that json as nix for this value.

              Schema at https://github.com/linux-nvme/libnvme/blob/ad61ac8a319ad0823c1c9861eecbf66125f8b9a1/doc/config-schema.json.
              Make sure to set some reconnect_delay and ctrl_loss_tmo to reconect after network loss like suspend.
              Though it doesn't seem to work for long suspends since it counts absolute time rather than awake time?
            '';
          };
        };
      };

      config = {
        services.tlshd.config = {
          authenticate = {
            keyrings = ".nvme";
          };
        };

        boot.kernelModules = [ "nvmet" ];

        systemd.services.nvmet = {
          wantedBy = [ "multi-user.target" ];
          requires = [
            # not required for key import but is for connecting
            config.systemd.services.tlshd.name
          ];
          script = ''
            ${cfg.nvmeCliPackage}/bin/nvme tls-key --import --keyfile ${cfg.keyFile}
            ${cfg.nvmetCliPackage}/bin/nvmetcli restore ${configFile}
          '';
          postStop = ''
            ${cfg.nvmetCliPackage}/bin/nvmetcli clear
          '';
          serviceConfig = {
            RemainAfterExit = true;
          };
        };

        networking.firewall = {
          # default nvme tcp port
          allowedTCPPorts = [ 4420 ];
        };

      };
    };

  flake.nixosModules.nvmeOfHost =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.nvmeOf.host;
      configFormat = pkgs.formats.json { };
      configFile = configFormat.generate "nvme-connect.json" cfg.config;
    in
    {
      imports = with self.nixosModules; [
        tlshd
      ];

      options = {
        services.nvmeOf.host = {
          keyFile = lib.mkOption {
            default = config.sops.secrets."share/nvme-of/keyfile".path;
            type = lib.types.path;
            description = keyFileDescription;
          };
          package = lib.mkOption {
            default = pkgs.nvme-cli;
            type = lib.types.package;
          };
          config = lib.mkOption {
            type = lib.types.listOf configFormat.type;
            description = ''
              Use `nvme connect/gen-tls-key/check-tls-key/tls-key` commands to connect and or setup tls keys.
              Then use `nvme --scan --dump` to see the json connection configs.
              Use that json as nix for this value.
            '';
          };
        };
      };

      config = {
        services.tlshd.config = {
          authenticate = {
            keyrings = ".nvme";
          };
        };

        boot.kernelModules = [ "nvme-fabrics" ];

        systemd.services.nvme-connect = {
          requires = [
            "network-online.target"
            # not required for key import but is for connecting
            config.systemd.services.tlshd.name
          ];
          script = ''
            ${cfg.package}/bin/nvme tls-key --import --keyfile ${cfg.keyFile}
            ${cfg.package}/bin/nvme connect --config ${configFile}
          '';
          postStop = ''
            ${cfg.package}/bin/nvme disconnect-all
          '';
          serviceConfig = {
            RemainAfterExit = true;
          };
        };

      };

    };

  flake.nixosModules.tlshd =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.tlshd;
      configFormat = pkgs.formats.ini { };
      configFile = configFormat.generate "tlshd.conf" cfg.config;
    in
    {
      options = {
        services.tlshd = {
          package = lib.mkOption {
            default = pkgs.ktls-utils;
            type = lib.types.package;
          };
          config = lib.mkOption {
            inherit (configFormat) type;
            description = "See man page for tlshd.conf(5)";
          };
        };
      };

      config = {
        # Based on
        # https://github.com/oracle/ktls-utils/blob/dba1bd102389a47b5390db24ce12ba04e6682849/systemd/tlshd.service
        systemd.services.tlshd = {
          description = "Handshake service for kernel TLS consumers";
          before = [ "remote-fs-pre.target" ];
          wantedBy = [ "remote-fs.target" ];
          script = ''
            ${cfg.package}/bin/tlshd -c ${configFile}
          '';
        };
      };
    };
}
