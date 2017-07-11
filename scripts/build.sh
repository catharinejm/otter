#!/usr/bin/env bash

set -euo pipefail

: ${DEBUG:=}

if [[ ! -z "$DEBUG" ]]; then
    set -x
fi

if ! which ponyc; then
    echo 'ponyc not found! please install pony to continue (https://github.com/ponylang/ponyc)' >&2
    exit 1
fi

mkdir -p build
CC=gcc ponyc --pic -o build src
mv build/src build/otter
