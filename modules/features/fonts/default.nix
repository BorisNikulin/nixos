{ self, inputs, ... }: {
  flake.nixosModules.fonts = { pkgs, ... }: {
    console.font = "Lat2-Terminus16";

    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];
      fontconfig = {
        defaultFonts = {
          monospace = [ "JetBrainsMono Nerd Font Propo" ];
        };
      };
    };

  };
}
