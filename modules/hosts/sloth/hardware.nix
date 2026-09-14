{ self, inputs, ... }: {
  flake.nixosModules.slothHardware =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        inputs.nixpkgs.nixosModules.notDetected
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [
        "kvm-amd"
        "amdgpu"
      ];
      boot.extraModulePackages = [ ];

      hardware.graphics.extraPackages = with pkgs; [
        # OpenCL
        rocmPackages.clr.icd
      ];

      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;

      hardware.rtl-sdr.enable = true;

      fileSystems."/" = {
        device = "framework/root";
        fsType = "zfs";
      };

      fileSystems."/nix" = {
        device = "framework/nix";
        fsType = "zfs";
      };

      fileSystems."/var" = {
        device = "framework/var";
        fsType = "zfs";
      };

      fileSystems."/home" = {
        device = "framework/home";
        fsType = "zfs";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/A566-E6D4";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [ ];

      # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
