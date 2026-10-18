{ samba, fetchurl }:
# nixpkgs is still on samba 4.23, whose smbd does not mount ZFS snapdir
# views on demand; the fix is the 4.24+ `automount fs types` option
# (samba bug 15991). 4.25.0 breaks nixpkgs' 4.x-no-persistent-install.patch,
# so this targets the latest 4.24. Remove this and use nixpkgs' samba once
# it ships 4.24 (update check: checks.x86_64-linux.sambaOverrideStillNeeded).
samba.overrideAttrs (
  final: prev: {
    version = "4.24.8";
    src = fetchurl {
      url = "https://download.samba.org/pub/samba/stable/samba-${final.version}.tar.gz";
      sha256 = "9b6611ab9ae718f47ef0d54008403d7b60a3c6c13e59b2aba769b085caea1d75";
    };
    # 4.24's `automount fs types` retry only fires on reopens via
    # /proc/self/fd; a first open of a child inside an unmounted ZFS
    # snapdir view fails with ENOENT before it is reached. Probe the
    # parent by full name (which makes the kernel walk into the view
    # and mount it) and retry the open.
    patches = prev.patches ++ [ ./snapdir-automount-retry.patch ];
  }
)
