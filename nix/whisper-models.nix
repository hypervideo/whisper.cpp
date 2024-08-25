{ pkgs, ... }:

let
  stdenv = pkgs.stdenv;
  fetchurl = pkgs.fetchurl;
  callPackage = pkgs.callPackage;
  buildEnv = pkgs.buildEnv;

  model = name: sha256:
    let
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${name}.bin";
    in
    stdenv.mkDerivation {
      name = "whisper-${name}";
      src = fetchurl {
        inherit url sha256;
      };

      unpackPhase = ''
        true
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/models
        cp $src $out/models/ggml-${name}.bin
        runHook postInstall
      '';
    };

  tiny = model "tiny" "sha256-vgfgSOHlma1GNByNKhNWRQl6U4IhZ4t6zdGxkZxuGyE=";
  tiny-en = model "tiny.en" "sha256-kh5M+Ghv3Zk9zQgaXaW2w2W/3hFi5ysI11rHUomSCx8=";
  # tiny-q5_1 = model "tiny-q5_1" "sha256-gYcQVo2jyhVonjGnQxl7UgAHhy/5V2I3val70bRpw9c=";
  # tiny-en-q5_1 = model "tiny.en-q5_1" "sha256-x3xXZvHO8JtrfUfyG1Rsvd1BV4hrO11tT3CekeZsfCs=";
  base = model "base" "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4=";
  base-en = model "base.en" "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
  # base-q5_1 = model "base-q5_1" "sha256-Qi8a5FKt5vMKAE1+XGpDGV5EM7w3C/I/rJzFkfAaiJg=";
  # base-en-q5_1 = model "base.en-q5_1" "sha256-S69w3Q18Qke6K4H6/ZwBAFrHfC+e8GTgDc8ZXQ4v3S8=";
  small = model "small" "sha256-G+OpsgY4Z7k35k4ux0gzZKeZF+FX+pjF2UtcH//qmHs=";
  small-en = model "small.en" "sha256-xhONbVjsyDIgl+D5h8MvG+i7ChhTKj+I9zTRu/nEHl0=";
  # small-q5_1 = model "small-q5_1" "sha256-roXkqTXXpWe9EC/lWvwWu1lb22GOEbL8dZG8CBIEEbs=";
  # small-en-q5_1 = model "small.en-q5_1" "sha256-v9/0iU3Ldrv2R9ViY+oqlmRUI/FmkXb0hEob+OR4rTA=";
  medium = model "medium" "sha256-bBTVre5fhjlAN7Tk6LWfFnO2zuEOPPCxG72+55wVYgg=";
  medium-en = model "medium.en" "";
  # medium-q5_0 = model "medium-q5_0" "";
  # medium-en-q5_0 = model "medium.en-q5_0" "";
  large-v1 = model "large-v1" "";
  large-v2 = model "large-v2" "";
  large-v2-q5_0 = model "large-v2-q5_0" "";
  large-v3 = model "large-v3" "";
  large-v3-q5_0 = model "large-v3-q5_0" "";

  whisper-cpp = callPackage ./whisper-cpp.nix { };

  quantize = name: type: base-model: stdenv.mkDerivation {
    name = "whisper-${name}-${type}";
    buildInputs = [ whisper-cpp base-model ];

    unpackPhase = ''
      true
    '';

    installPhase = ''
      mkdir -p $out/models
      ${whisper-cpp}/bin/quantize ${base-model}/models/ggml-${name}.bin $out/models/ggml-${name}-${type}.bin ${type}
    '';
  };

  quantize-types = [
    "q2_k"
    "q3_k"
    "q4_0"
    "q4_1"
    "q4_k"
    "q5_0"
    "q5_1"
    "q5_k"
    "q6_k"
    "q8_0"
  ];

  tiny-quantized-models = builtins.foldl' (models: type: models // { "tiny-${type}" = quantize "tiny" type tiny; }) { } quantize-types;
  tiny-en-quantized-models = builtins.foldl' (models: type: models // { "tiny-en-${type}" = quantize "tiny.en" type tiny-en; }) { } quantize-types;
  base-quantized-models = builtins.foldl' (models: type: models // { "base-${type}" = quantize "base" type base; }) { } quantize-types;
  base-en-quantized-models = builtins.foldl' (models: type: models // { "base-en-${type}" = quantize "base.en" type base-en; }) { } quantize-types;
  small-quantized-models = builtins.foldl' (models: type: models // { "small-${type}" = quantize "small" type small; }) { } quantize-types;
  small-en-quantized-models = builtins.foldl' (models: type: models // { "small-en-${type}" = quantize "small.en" type small-en; }) { } quantize-types;
  medium-quantized-models = builtins.foldl' (models: type: models // { "medium-${type}" = quantize "medium" type medium; }) { } quantize-types;
  medium-en-quantized-models = builtins.foldl' (models: type: models // { "medium-en-${type}" = quantize "medium.en" type medium-en; }) { } quantize-types;

  tiny-models = buildEnv {
    name = "whisper-tiny-models";
    paths = [ tiny tiny-en ] ++ (builtins.attrValues tiny-quantized-models) ++ (builtins.attrValues tiny-en-quantized-models);
  };

  base-models = buildEnv {
    name = "whisper-base-models";
    paths = [ base base-en ] ++ (builtins.attrValues base-quantized-models) ++ (builtins.attrValues base-en-quantized-models);
  };

  small-models = buildEnv {
    name = "whisper-small-models";
    paths = [ small small-en ] ++ (builtins.attrValues small-quantized-models) ++ (builtins.attrValues small-en-quantized-models);
  };

  medium-models = buildEnv {
    name = "whisper-medium-models";
    paths = [ medium medium-en ] ++ (builtins.attrValues medium-quantized-models);
  };

in

{
  inherit tiny tiny-en;
  inherit base base-en;
  inherit small small-en;
  inherit medium medium-en;
  inherit large-v1;
  inherit large-v2 large-v2-q5_0;
  inherit large-v3 large-v3-q5_0;

  inherit tiny-models base-models small-models medium-models;
} // tiny-quantized-models // tiny-en-quantized-models // base-quantized-models // base-en-quantized-models // small-quantized-models // small-en-quantized-models // medium-quantized-models // medium-en-quantized-models
