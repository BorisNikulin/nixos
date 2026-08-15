{ self, inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.nvmet-cli = pkgs.callPackage ./_package.nix { };
  };
}
