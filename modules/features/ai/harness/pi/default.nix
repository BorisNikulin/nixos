{ self, inputs, ... }: {
  flake.nixosModules.aiHarnessPi =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        pi-coding-agent
      ];
    };
}
