{ self, inputs, ... }: {
  # imports = [
  #   inputs.flake-root.flakeModule
  # ];

  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    {
      apps.update = {
        type = "app";
        program = lib.getExe self'.packages.update;
      };

      packages.update = pkgs.writeShellApplication {
        name = "update";
        runtimeInputs = with self'.packages; [
          pkgs.git
          pkgs.nix

          updateCloudflareIpsDriftCheck
        ];
        text = ''
          # shellcheck disable=SC2329
          onError() {
            echo "Update had an error"
            echo "Consider 'git reset @{1}'"
          }

          trap onError ERR

          nix flake update --commit-lock-file --commit-lockfile-summary "chore(update): Update flake.lock"
          nix flake check

          updateCloudflareIpsDriftCheck

          # NVMe-oF write failures: nvmet_tcp targets advertise MDTS=0 until the
          # upstream .get_mdts patch lands. If resolved and in the kernel we run,
          # remove the max_sectors_kb udev mitigation in
          # modules/features/shares/nvme-of/default.nix (nvmeOfHost).
          echo "Check https://github.com/truenas/truenas-proxmox-plugin/issues/96 (nvmet_tcp MDTS=0) for resolution; if the patch landed locally, drop the nvme-of max_sectors_kb workaround."

        '';
      };
    };
}
