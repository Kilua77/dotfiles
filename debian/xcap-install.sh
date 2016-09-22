#!/bin/bash
cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

# create tmp dir to save sources
mkdir -p tmp && cd tmp
# install dependencies
sudo apt-get install git gcc make pkg-config libx11-dev libxtst-dev libxi-dev
# download source
git clone https://github.com/alols/xcape.git
# install xcape
cd xcape
make
sudo make install
cd $DOFILES_ROOT
