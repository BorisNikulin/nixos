{ self, inputs, ... }: {
  flake.nixosModules.time = { ... }: {
    time.timeZone = "America/Los_Angeles";
  };
}
