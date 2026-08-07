# https://github.com/nydragon/calibre-plugins/blob/3f99ce55a85120a2408ec80284c6c14c4e701e0b/packages/dedrm-plugin/default.nix
{
  stdenv,
  fetchFromGitHub,
  python311,
  ensureNewerSourcesForZipFilesHook,
  unzip,

  ...
}:
stdenv.mkDerivation {
  name = "dedrm-tools";

  src = fetchFromGitHub {
    owner = "noDRM";
    repo = "DeDRM_tools";
    rev = "7379b453199ed1ba91bf3a4ce4875d5ed3c309a9";
    hash = "sha256-Hq/DBYeJ2urJtxG+MiO2L8TGZ9/kLue1DXbG4/KJFhc=";
  };

  buildInputs = [
    python311
    ensureNewerSourcesForZipFilesHook
    unzip
  ];

  outputs = [
    "out"
    "obok"
  ];

  buildPhase = ''
    set -e

    python3 ./make_release.py

    mkdir tmp
    unzip DeDRM_tools.zip -d tmp

    cp tmp/DeDRM_plugin.zip $out
    cp tmp/Obok_plugin.zip $obok
  '';
}
