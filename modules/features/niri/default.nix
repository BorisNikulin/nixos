{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  imports = [
    inputs.wrappers.flakeModules.wrappers
  ];

  flake.nixosModules.niri = moduleWithSystem (
    { self', inputs', ... }:
    { pkgs, lib, ... }:
    {

      programs.regreet = {
        enable = true;
      };

      # services.greetd = {
      #   enable = true;
      #   settings = {
      #     default_session = {
      #       command = "${self'.packages.niri}/bin/niri-session";
      #     };
      #   };
      # };

      programs.niri = {
        enable = true;
        package = self'.packages.niri;
      };

      security.polkit.enable = true;
      services.gnome.gnome-keyring.enable = true; # secret service impl

      # TODO: export own wrapped packages as needed.
      #  Quickshell for all?
      environment.systemPackages = with pkgs; [
        xwayland-satellite
      ];

    }
  );

  flake.wrappers.niri = moduleWithSystem (
    {
      self',
      inputs',
      system,
      ...
    }:
    { pkgs, wlib, ... }:
    {
      imports = [ wlib.wrapperModules.niri ];

      "config.kdl".path = ./config.kdl;

    }
  );

  flake.homeModules.niri = { pkgs, lib, ... }: {
    home.packages = with pkgs; [
      alacritty
      fuzzel
      swaylock
      mako
      swayidle

      seahorse # gnome keyring gui
    ];

    # Writes a .../default/index.theme with name Default
    # that points to the cursor theme.
    # This stable name/path is used in niri's cursor config.
    home.pointerCursor = {
      enable = true;
      x11.enable = true;
      gtk.enable = true;
      # There is a hypercursor backend but no niri.
      # niri only accepts "cursor" block configs in it's config proper.

      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Classic";
    };
  };
}
