{ self, inputs, ... }: {
  flake.nixosModules.shareSmbServer =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      #TODO: figure our user situation
      # curently it's imperative and requires manually enrolling a unix user to samba
      services.samba = {
        enable = true;
        openFirewall = true;
        settings = {
          global = {
            "workgroup" = "WORKGROUP";
            "server string" = config.networking.hostName;
            "netbios name" = config.networking.hostName;
            "security" = "user";
            # "use sendfile" = "yes";
            #"max protocol" = "smb2";
            # note: localhost is the ipv6 localhost ::1
            "hosts allow" = "10.0.0.0/8";
            # "hosts deny" = "0.0.0.0/0";
            "guest account" = "nobody";
            "map to guest" = "bad user";
          };
          "share-fast" = {
            # TODO: convert to opions and set in disko module
            "path" = config.disko.devices.zpool.fast.datasets."encrypted/share".mountpoint;
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "no";
            # "valid users" = "";
            # "create mask" = "0644";
            # "directory mask" = "0755";
            # "force user" = "username";
            # "force group" = "groupname";
          };
          "share-main" = {
            "path" = config.disko.devices.zpool.main.datasets."encrypted/share".mountpoint;
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "no";
            # "valid users" = "";
            # "create mask" = "0644";
            # "directory mask" = "0755";
            # "force user" = "username";
            # "force group" = "groupname";
          };
          "media" = {
            "path" = config.disko.devices.zpool.main.datasets.media.mountpoint;
            "force group" = "media";
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "no";
          };
        };
      };
    };
}
