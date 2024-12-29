{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "main";
  home.homeDirectory = "/home/main";


  home.packages = with pkgs; [
    firefox
    tree
    vesktop
    yubikey-personalization
    yubikey-manager
    yubioath-flutter
    flameshot
    mpv
    jellyfin-media-player
    digikam
    darktable
  ];

  programs.bash = {
    enable = true;
  };

  programs.zsh = {
    enable = true;

    shellAliases = {
      ll = "ls -lah";
    };
  };

  programs.git = {
    enable = true;
    
    userName = "Boris Nikulin";
    userEmail = "NikulinBE@gmail.com";
    signing = {
      key = "756B53520F832A2C53B1509D218C4D957DFFFB72";
      signByDefault = true;
    };
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";
}