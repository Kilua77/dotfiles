#!/bin/sh
# fixture topic check — proves the engine doctor runs a layer's */check.sh
# (PR2) and that the layer linked what it declared.
if [ -L "$HOME/.homedot" ]; then
  echo "ok: fixture — ~/.homedot is linked"
else
  echo "TODO: fixture — ~/.homedot is not linked"
fi
