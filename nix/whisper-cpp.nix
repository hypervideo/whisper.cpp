{ lib
, stdenv
, python3
, makeWrapper
, cmake
, which
, fetchFromGitHub
, llvmPackages
}:

stdenv.mkDerivation {
  name = "whisper-cpp";

  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = "whisper.cpp";
    rev = "refs/fc21a40";
    hash = "sha256-hIEIu7feOZWqxRskf6Ej7l653/9KW8B3cnpPLoCRBAc=";
  };

  nativeBuildInputs = [
    which
    makeWrapper
    cmake
    python3
    llvmPackages.openmp
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    make install
    cp ./bin/quantize $out/bin/quantize
    cp ./bin/main $out/bin/main
    cp ./bin/server $out/bin/server
    runHook postInstall
  '';

  # FIXME! currently rpath error mentioning /build ... ?
  dontFixup = true;
}
