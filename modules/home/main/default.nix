{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
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

  flake.homeModules.main =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        self.homeModules.calibre
      ];

      home.username = "main";
      home.homeDirectory = "/home/main";

      home.packages = with pkgs; [
        firefox
        tree
        # May need to manually start once to set keyring to non basic if on uncommon DE like niri.
        # element-desktop --password-store="gnome-libsecret"
        # https://discourse.nixos.org/t/element-desktop-no-longer-working-with-nixos-25-05-on-a-minimal-desktop-i3-or-xterm-due-to-unsupported-keyring/69731/5
        # https://github.com/electron/electron/issues/39789
        element-desktop

        mpv
        jellyfin-media-player

        digikam
        darktable

        sdrpp
        sdrangel

        # For kobo desktop for calibre
        wineWow64Packages.stable

        winbox

        # TODO: pick a file manager
        # Nautilus is default with niri and gnome portal but can be changed
        nautilus
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
        presets = [
          "nerd-font-symbols"
        ];
        settings = {
          nix_shell = {
            # enable support for nix shell
            heuristic = true;
          };
          memory_usage = {
            disabled = false;
          };
        };
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
        extraConfig =
          let
            # GPG status icons (Nerd Font):
            #   G=good        → 󰄬 check (green)
            #   B=bad         → 󰅖 close (red)
            #   U=unknown val → 󰄬 check (yellow)
            #   X=sig expired → 󰥕 clock-alert (red)
            #   Y=key expired → 󰾨 clock-check (yellow)
            #   R=revoked     → 󰌊 key-remove (red)
            #   E=missing key → 󰷖 key-outline (yellow)
            #   N=no sig      → (blank)
            # requires " [%G?]" in the format string
            gpgSed = "sed 's/\\[G\\]/\\x1b[32m󰄬\\x1b[0m/g; s/\\[B\\]/\\x1b[31m󰅖\\x1b[0m/g; s/\\[U\\]/\\x1b[33m󰄬\\x1b[0m/g; s/\\[X\\]/\\x1b[31m󰥕\\x1b[0m/g; s/\\[Y\\]/\\x1b[33m󰾨\\x1b[0m/g; s/\\[R\\]/\\x1b[31m󰌊\\x1b[0m/g; s/\\[E\\]/\\x1b[33m󰷖\\x1b[0m/g; s/ \\[N\\]//g'";
          in
          {
            alias.co = "checkout";
            alias.graph = "!git log --graph --abbrev-commit --decorate --color=always --format='%C(bold blue)%h%C(reset) %C(bold green)(%ar)%C(reset)%d %C(dim white)%an%C(reset) [%G?]%n%w(120,2,2)%C(white)%s%C(reset)' --all | ${gpgSed} | less -RFX";
            alias.g = "graph";
            alias.shortgraph = "!git --no-pager log -20 --graph --abbrev-commit --decorate --color=always --format='%C(bold blue)%h%C(reset) %C(bold green)(%ar)%C(reset)%d %C(dim white)%an%C(reset) [%G?] %C(white)%<(60,trunc)%s%C(reset)' --all | ${gpgSed}";
            alias.sg = "shortgraph";
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
