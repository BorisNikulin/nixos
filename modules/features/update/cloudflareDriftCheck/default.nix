{ self, inputs, ... }: {
  perSystem = { self', pkgs, ... }: {
    packages.updateCloudflareIpsDriftCheck = pkgs.writeShellApplication {
      name = "updateCloudflareIpsDriftCheck";
      runtimeInputs = with pkgs; [
        nix
      ];
      runtimeEnv = {
        inherit (self'.packages.cloudflareIpsJson) name url hash;
      };
      text = ''
        nix store prefetch-file "$url" --name "$name" --expected-hash "$hash"
      '';
    };
  };
}
