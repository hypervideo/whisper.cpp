{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        emscripten = pkgs.callPackage ./nix/emscripten.nix {
          llvmPackages = pkgs.llvmPackages_git;
        };

        llvmPackages = pkgs.llvmPackages_18;

        whisper-models = import ./nix/whisper-models.nix { inherit pkgs; };

        whisper-cpp = (pkgs.callPackage ./nix/whisper-cpp.nix {
          inherit llvmPackages;
        });
        whisper-cpp-wasm = (pkgs.callPackage ./nix/whisper-cpp-wasm.nix {
          inherit emscripten llvmPackages;
        });

        whisper-cpp-local = whisper-cpp.overrideAttrs { src = ./.; };
        whisper-cpp-wasm-local = whisper-cpp-wasm.overrideAttrs { src = ./.; };
      in
      {

        packages = {
          inherit whisper-cpp whisper-cpp-wasm whisper-cpp-local whisper-cpp-wasm-local;
        } // whisper-models;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cmake
            emscripten
            makeWrapper
            llvmPackages.openmp

            llvmPackages.lldb
            llvmPackages.libstdcxxClang
            clang-analyzer
            llvmPackages.libllvm
            cppcheck
            ccls
          ];
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

          shellHook = ''
            export CPLUS_INCLUDE_PATH="${emscripten}/system/include:$CPLUS_INCLUDE_PATH"
          '';
        };
      }
    );
}
