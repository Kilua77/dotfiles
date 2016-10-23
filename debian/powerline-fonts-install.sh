#!/bin/bash
cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

# create tmp dir to save sources
mkdir -p tmp && cd tmp
# download source
git clone https://github.com/powerline/fonts.git
# install fonts
cd fonts
./install.sh
cd $DOFILES_ROOT
