#!/bin/bash
cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

# create tmp dir to save sources
mkdir -p tmp && cd tmp
# download source
git clone https://github.com/Kilua77/fonts.git
# install fonts
cd fonts
sudo ./install.sh
cd $DOFILES_ROOT
