default:
    just --list

build:
    make

run model:
    ./main -m models/ggml-{{ model }}.bin -f samples/jfk.wav

download model="":
    bash ./models/download-ggml-model.sh {{ model }}

# type = "q2_k" or 10
# type = "q3_k" or 11
# type = "q4_0" or 2
# type = "q4_1" or 3
# type = "q4_k" or 12
# type = "q5_0" or 8
# type = "q5_1" or 9
# type = "q5_k" or 13
# type = "q6_k" or 14
# type = "q8_0" or 7
# just quantize tiny.en q2_k
quantize model type:
    # make quantize
    ./quantize models/ggml-{{ model }}.bin models/ggml-{{ model }}-{{ type }}.bin {{ type }}
    du -sh models/ggml-{{ model }}-{{ type }}.bin
    ./main -m models/ggml-{{ model }}-{{ type }}.bin ./samples/jfk.wav

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
