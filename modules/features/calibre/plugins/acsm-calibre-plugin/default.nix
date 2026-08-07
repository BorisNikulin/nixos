{ self, inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.calibrePluginsAcsm = pkgs.callPackage ./_package.nix { };
  };
}
