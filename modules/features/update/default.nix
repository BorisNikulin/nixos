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
        '';
      };
    };
}
