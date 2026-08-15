{
  lib,
  python3Packages,
  fetchurl,
}:
# Copied from nixpkgs with a bump to a working version (0.7 -> 0.8)
# and added the missing six dep from both 0.7 and 0.8 versions.
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "nvmet-cli";
  version = "0.8";
  format = "setuptools";

  src = fetchurl {
    url = "ftp://ftp.infradead.org/pub/nvmetcli/nvmetcli-${finalAttrs.version}.tar.gz";
    sha256 = "58qbQF7GlGyc+az5xSxrKjFEdmajkFrMdLmWq8xDKV8=";
  };

  buildInputs = with python3Packages; [ nose2 ];

  propagatedBuildInputs = with python3Packages; [
    configshell-fb
    six
  ];

  # This package requires the `nvmet` kernel module to be loaded for tests.
  doCheck = false;

  meta = {
    description = "NVMe target CLI";
    mainProgram = "nvmetcli";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ hoverbear ];
  };
})
