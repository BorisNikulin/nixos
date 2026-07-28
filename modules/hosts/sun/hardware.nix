{ self, inputs, ... }: {
  flake.nixosModules.sunHardware =
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
        "ehci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      networking.useDHCP = lib.mkDefault true;
      # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
      # networking.interfaces.eno2.useDHCP = lib.mkDefault true;
      # networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;
      # networking.interfaces.enp7s0d1.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
