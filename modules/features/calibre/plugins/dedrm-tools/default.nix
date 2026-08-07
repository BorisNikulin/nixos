{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      deDrm = pkgs.callPackage ./_package.nix { };
    in
    {
      packages.calibrePluginsDeDrm = deDrm.out;
      packages.calibrePluginsObok = deDrm.obok;
    };
}
