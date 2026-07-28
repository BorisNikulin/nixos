{ inputs, ... }: {
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  flake.nixosModules.mainUser = { pkgs, ... }: {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.main = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "plugdev"
        "dialout"
      ];
      shell = pkgs.zsh;
    };

    programs.zsh.enable = true;

    # For zsh enableCompletion of system packages
    environment.pathsToLink = [ "/share/zsh" ];
  };

  flake.homeModules.main = { config, pkgs, ... }: {
    home.username = "main";
    home.homeDirectory = "/home/main";

    home.packages = with pkgs; [
      firefox
      tree
      element-desktop
      flameshot

      mpv
      jellyfin-media-player

      digikam
      darktable

      sdrpp
      sdrangel
    ];

    # TODO: move away from home manager to nix-wrapper-modules

    programs.bash = {
      enable = true;
    };

    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      defaultKeymap = "viins";

      shellAliases = {
        ll = "ls -algh";
      };
    };

    programs.starship = {
      enable = true;
    };

    programs.alacritty = {
      enable = true;
      settings = {
        terminal.shell = "${pkgs.zsh}/bin/zsh";
      };
    };

    programs.git = {
      enable = true;

      settings.user = {
        name = "Boris Nikulin";
        email = "NikulinBE@gmail.com";
      };
      signing = {
        key = "756B53520F832A2C53B1509D218C4D957DFFFB72";
        signByDefault = true;
      };
    };

    programs.vim = {
      enable = true;
      defaultEditor = true;
    };

    programs.home-manager.enable = true;

    home.stateVersion = "26.11";
  };
}
