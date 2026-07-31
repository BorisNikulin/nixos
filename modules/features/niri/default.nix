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
        alacritty
        fuzzel
        swaylock
        mako
        swayidle

        xwayland-satellite

        seahorse # gnome keyring gui
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

      package = inputs.nixpkgs-stable.legacyPackages.${system}.niri;
      "config.kdl".path = ./config.kdl;

    }
  );

  # flake.wrappers.niri = { pkgs, wlib, ... }: {
  #   imports = [ wlib.wrapperModules.niri ];
  #
  #   niri = inputs.nixpkgs-master.legacyPackages.${system}.niri;
  #
  #   # settings = {
  #   # };
  # };

  perSystem =
    {
      self',
      inputs',
      pkgs,
      ...
    }:
    {
      # packages.aniri = pkgs.niri;

    };
}
