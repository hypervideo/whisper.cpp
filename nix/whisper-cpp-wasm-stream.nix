{ lib
, stdenv
, python3
, llvmPackages
, makeWrapper
, cmake
, which
, emscripten
, fetchFromGitHub
}:

stdenv.mkDerivation {
  name = "whisper_cpp_wasm_stream";

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
    emscripten
    python3
  ];

  buildInputs = [
    llvmPackages.openmp
  ];

  configurePhase = ''
    HOME=$TMPDIR
    mkdir -p .emscriptencache
    export EM_CACHE=$(pwd)/.emscriptencache
    emcmake cmake . $cmakeFlags -DCMAKE_INSTALL_PREFIX=$out
  '';

  buildPhase = ''
    make -j $(nproc) libstream libstream/fast
  '';

  postInstall = ''
    mkdir -p $out/bin
    cp -r bin/* $out/bin
  '';
}

