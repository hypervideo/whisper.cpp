{ lib
, stdenv
, python3
, makeWrapper
, cmake
, which
, fetchFromGitHub
, llvmPackages
, emscripten
, callPackage
}:

let
  whisper-cpp = callPackage ./whisper-cpp.nix { };
in
whisper-cpp.overrideAttrs (final: prev: {
  name = "whisper-cpp-wasm";

  buildInputs = prev.nativeBuildInputs ++ [
    emscripten
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

  installPhase = ''
    runHook preInstall
    make install
    mkdir -p $out/bin
    cp -r bin/* $out/bin
    runHook postInstall
  '';
})
