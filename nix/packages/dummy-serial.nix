{
  stdenv,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  pname = "dummy-serial";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "notashelf";
    repo = "dummy-serial";
    rev = "v0.1.0";
    hash = "sha256-+zXA5Ko8ikgkmkm1eyx2VMQQjp61osSpq4K+d9WEqq8=";
  };

  makeFlags = ["TARGET=main"];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -rvf main $out/bin/dummy-serial
    runHook postInstall
  '';

  meta = {
    description = "Create dummy serial ports through PseudoTTYs";
    mainProgram = "dummy-serial";
  };
}
