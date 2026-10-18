{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  curl,
  jq,
  jo,
  lldap,
}:
# Bootstrap script from lldap.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lldap-bootstrap";
  version = "0.6.3";

  src = fetchFromGitHub {
    owner = "lldap";
    repo = "lldap";
    rev = "v${finalAttrs.version}";
    hash = "sha256-EafYBCorK5t8ZLoXTjqLg+Q6GDRZjalpRqSoVySdpOk=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bash ];

  dontBuild = true;

  installPhase = ''
    install -Dm755 $src/scripts/bootstrap.sh $out/bin/lldap-bootstrap
    wrapProgram $out/bin/lldap-bootstrap \
      --prefix PATH : ${
        lib.makeBinPath [
          curl
          jq
          jo
          lldap
        ]
      } \
      --set LLDAP_SET_PASSWORD_PATH ${lldap}/bin/lldap_set_password
  '';

  meta = {
    description = "Convergent bootstrap for LLDAP users and groups";
    mainProgram = "lldap-bootstrap";
    homepage = "https://github.com/lldap/lldap";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
})
