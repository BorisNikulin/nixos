{ self, inputs, ... }: {
  flake.nixosModules.sunConfiguration =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = with self.nixosModules; [
        inputs.sops-nix.nixosModules.sops
        sops

        inputs.disko.nixosModules.disko
        sunDisko

        sunHardware
        bootDefault

        mainUser

        # shareGameIscsiTarget (legacy; replaced by NVMe-oF — candidate for deletion)
        shareNvmeOfTargetGame
        shareSmbServer

        postfix

        domain
        certs
        caddy
        auth
        monitoring

        matrixHomeServer
        arr

        backupSun
      ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nixpkgs.config.allowUnfree = true;

      boot = {
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = true;
        };
      };

      services.zfs.trim = {
        enable = true;
        interval = "weekly";
      };

      services.zfs.autoScrub = {
        enable = true;
        interval = " *-*-1,15 08:00:00";
        randomizedDelaySec = "1h";
      };

      services.zfs.zed.settings = {
        ZED_DEBUG_LOG = "/tmp/zed.debug.log";
        ZED_EMAIL_ADDR = [ "root" ];
        ZED_EMAIL_PROG = "${pkgs.postfix}/bin/sendmail";
        ZED_EMAIL_OPTS = "@ADDRESS@";

        ZED_NOTIFY_INTERVAL_SECS = 60;
        ZED_NOTIFY_VERBOSE = true;

        ZED_USE_ENCLOSURE_LEDS = true;
        ZED_SCRUB_AFTER_RESILVER = true;
      };
      # this option does not work; will return error
      services.zfs.zed.enableMail = false;

      services.fwupd.enable = true;

      services.smartd = {
        enable = true;
        notifications.mail.enable = true;
        devices =
          let
            disks = builtins.attrValues config.disko.devices.disk;
            filterByZfsPool =
              pool: builtins.filter (disk: disk.content.partitions.zfs.content.pool == pool) disks;
            zrootDisks = filterByZfsPool "zroot";
            fastDisks = filterByZfsPool "fast";
            mainDisks = filterByZfsPool "main";
            addOptions =
              options:
              builtins.map (disk: {
                inherit (disk) device;
                inherit options;
              });
            ssdOptions = addOptions "-H -W 10,40,50 -s (S/../.././08|L/../01/./07)";
            hddOptions = addOptions "-H -W 5,30,40 -s (S/../.././08|L/../01/./07)";

          in
          builtins.concatLists [
            (ssdOptions zrootDisks)
            (ssdOptions fastDisks)
            (hddOptions mainDisks)
          ];
      };

      services.caddy = {
        virtualHosts."jellyfin.rhakotis.xyz" = {
          useACMEHost = "rhakotis.xyz";
          extraConfig = ''
            reverse_proxy http://localhost:8096
          '';
        };
      };

      security.acme = {
        certs."ldap.rhakotis.xyz" = {
          group = config.systemd.services.lldap.serviceConfig.Group;

          domain = "ldap.rhakotis.xyz";
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          environmentFile = config.sops.secrets."cloudflare/dns_api_token".path;
        };
      };

      # TODO: Submit PR to add user and group creation to (see memcached.nix for example)
      # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/databases/lldap.nix
      # Bind account used by authelia (and future LDAP clients) to read the
      # directory and set user passwords; lldap_password_manager grants reads
      # plus password changes (no general write, no admin).
      services.lldap.bootstrap.users = {
        "bind-authelia" = {
          email = "bind-authelia@rhakotis.xyz";
          groups = [ "lldap_password_manager" ];
          password_file = config.sops.secrets."lldap/bind_pass/authelia".path;
        };

        # focu5 is the first real user. Per-app lldap groups are declared in each
        # app module via auth.apps (grafana, radarr, sonarr) and aggregated by the
        # auth feature; users reference them by name here.
        focu5 = {
          # Placeholder identity details; edit in the lldap UI and rerun the
          # bootstrap to see whether manual edits persist (bootstrap is convergent,
          # so expect them to revert).
          email = "NikulinBE@gmail.com";
          displayName = "Boris";
          groups = [
            "radarr-admin"
            "sonarr-admin"
            "grafana"
          ];
          password_file = config.sops.secrets."lldap/user_pass/focu5".path;
        };
      };

      networking.firewall.allowedTCPPorts = [ config.services.prometheus.port ];

      services.jellyfin = {
        enable = true;
        openFirewall = true;
        group = "media";
        dataDir = config.disko.devices.zpool.fast.datasets."encrypted/app/jellyfin".options.mountpoint;
        cacheDir =
          config.disko.devices.zpool.fast.datasets."encrypted/app/jellyfin".options.mountpoint + "/cache";
      };

      networking.hostName = "sun";
      # hostId derived from systemd machine-id; head -c 8 /etc/machine-id
      networking.hostId = "3d150210";
      # Pick only one of the below networking options.
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
      networking.nftables.enable = true;

      systemd.network = {
        enable = true;
        networks."10-lan" = {
          matchConfig.Name = "enp7s0";
          networkConfig = {
            # start a DHCP client for IPv4 addressing/routing
            DHCP = "ipv4";
            # accept router advertisements for stateless IPv6 (SLAAC)
            IPv6AcceptRA = true;
          };
          linkConfig.RequiredForOnline = "routable";
        };
      };
      # networkd supersedes dhcpcd; disable scripting DHCP to keep the two from managing the same interfaces
      networking.useDHCP = false;

      # Set your time zone.
      time.timeZone = "America/Los_Angeles";

      # Configure network proxy if necessary
      # networking.proxy.default = "http://user:password@proxy:port/";
      # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";
      console = {
        font = "Lat2-Terminus16";
        keyMap = "us";
      };

      # For zsh enableCompletion of system packages
      environment.pathsToLink = [ "/share/zsh" ];

      # Enable sound.
      # hardware.pulseaudio.enable = true;
      # OR
      #services.pipewire = {
      #  enable = true;
      #  alsa.enable = true;
      #  alsa.support32Bit = true;
      #  pulse.enable = true;
      #};

      programs.zsh.enable = true;

      # Define a user account. Don't forget to set a password with ‘passwd’.
      users.users.root = {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJApd1snd5+dTT3y3G44+yhZgzGjTJIg0dLOV0Ssk/CI"
        ];
      };

      users.groups.media = { };
      users.groups.apps = { };

      users.users.main = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "plugdev"
          "media"
        ]; # Enable ‘sudo’ for the user.
        # TODO: move this to nas user? and call it main.
        # shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJApd1snd5+dTT3y3G44+yhZgzGjTJIg0dLOV0Ssk/CI"
        ];
      };

      # Also need to enroll as smb user for smb access.
      # TODO: make this not imperitive.
      users.users.boris = {
        isNormalUser = true;
        createHome = false;
        useDefaultShell = false;
        hashedPasswordFile = config.sops.secrets."boris/passwordHash".path;
        extraGroups = [
          "media"
        ];
      };

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        wget
        git
      ];

      # List services that you want to enable:

      # Enable the OpenSSH daemon.
      services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = false;
        };
      };

      networking.firewall.enable = true;

      system.stateVersion = "26.05";
    };
}
