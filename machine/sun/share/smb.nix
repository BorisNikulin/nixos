{
  config,
  lib,
  pkgs,
  ...
}:
{
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
        "hosts allow" = "10.0.0.0/16";
        # "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "share" = {
        "path" = config.disko.devices.zpool.main.datasets.share.mountpoint;
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        # "valid users" = "boris";
        # "create mask" = "0644";
        # "directory mask" = "0755";
        # "force user" = "username";
        # "force group" = "groupname";
      };
      "media" = {
        "path" = config.disko.devices.zpool.main.datasets.media.mountpoint;
        "force group" = "groupname";
      };
    };
  };

}
