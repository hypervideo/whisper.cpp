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

        whisper_cpp_wasm_stream = (pkgs.callPackage ./nix/whisper-cpp-wasm-stream.nix {
          inherit emscripten;
          llvmPackages = pkgs.llvmPackages_18;
        }).overrideAttrs (oldAttrs: {
          src = ./.;
        });

        llvmPackages = pkgs.llvmPackages_18;

      in
      {
        packages = {
          inherit whisper_cpp_wasm_stream emscripten;
        };

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
