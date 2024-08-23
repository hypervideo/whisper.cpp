default:
    just --list

run:
    # make
    ./main -f samples/jfk.wav

model-download:
    bash ./models/download-ggml-model.sh base.en
    bash ./models/download-ggml-model.sh tiny.en

example-quantize:
    # make quantize
    ./quantize models/ggml-tiny.en.bin models/ggml-tiny.en-q5_0.bin q5_0
    ./main -m models/ggml-tiny.en-q5_0.bin ./samples/jfk.wav

example-wasm-stream:
    #!/usr/bin/env sh
    set -e

    # build using Emscripten (v3.1.2)
    mkdir -p build-em && cd build-em
    emcmake cmake ..
    make -j

    # copy the produced page to your HTTP path
    # cp bin/stream.wasm/*       /path/to/html/
    # cp bin/libstream.worker.js /path/to/html/
