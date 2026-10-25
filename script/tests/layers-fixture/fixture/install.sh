#!/bin/sh
# fixture topic installer — proves the engine's install walker runs a
# layer's */install.sh with cwd set to the topic directory.
echo "fixture: install.sh ran (LAYER_ROOT=${LAYER_ROOT:-unset})"
