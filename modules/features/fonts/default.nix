{ self, inputs, ... }: {
  flake.nixosModules.fonts = { pkgs, ... }: {
    console.font = "Lat2-Terminus16";

    fonts = {
      fontDir.enable = true;

      enableDefaultPackages = false;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono

        # enableDefaultPackages without pkgs.freefont_ttf.
        # https://discourse.nixos.org/t/display-braille-characters-btop-25-11-kde-plasma/75017
        # https://github.com/NixOS/nixpkgs/blob/1559d3daa3ecc813a650b79375ea61b6741b8746/nixos/modules/config/fonts/packages.nix#L42
        # GNU FreeFont has unusable braille which is used for TUI graphs like btop.
        dejavu_fonts
        gyre-fonts # TrueType substitutes for standard PostScript fonts
        liberation_ttf
        unifont
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
      ];

      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [
            "JetBrainsMono Nerd Font Propo"
            "Noto Sans Mono"
            "DejaVu Sans Mono"
          ];
          sansSerif = [
            "Noto Sans"
            "DejaVu Sans"
          ];
          serif = [
            "Noto Serif"
            "DejaVu Serif"
          ];
        };
      };
    };

  };
}
