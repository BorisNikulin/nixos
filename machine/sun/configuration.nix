# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5)e man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./share/iscsi.nix
    ./share/smb.nix
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
    interval = "monthly";
  };

  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
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

  services.postfixRootToGmail = {
    enable = true;
    smtpSaslPasswordMap = config.sops.secrets."postfix/sasl_password_map".path;
    virtualAliasMap = config.sops.secrets."postfix/virtual_alias_map".path;
  };

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

  # https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/monitoring/prometheus/exporters/node.nix
  services.prometheus.exporters.node = {
    enable = true;
    port = 9002;
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
    enabledCollectors = [
      "systemd"
      "ethtool"
    ];
    # /nix/store/zgsw0yx18v10xa58psanfabmg95nl2bb-node_exporter-1.8.1/bin/node_exporter  --help
  };

  # https://wiki.nixos.org/wiki/Prometheus
  # https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters-configuration
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/default.nix
  services.prometheus = {
    enable = true;
    port = 9001;
    stateDir = "prometheus"; # /var/lib/prometheus
    globalConfig.scrape_interval = "1m";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ config.services.prometheus.port ];

  networking.hostName = "sun";
  # hostId derived from systemd machine-id; head -c 8 /etc/machine-id
  networking.hostId = "3d150210";
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.nftables.enable = true;
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

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

  users.users.main = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "plugdev"
      "media"
    ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJApd1snd5+dTT3y3G44+yhZgzGjTJIg0dLOV0Ssk/CI"
    ];
  };

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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
