#!/usr/bin/env bash
#
# Run all plugin installers

set -e

ANTIGEN=$HOME/.antigen
PLUGIN_DIR=$ANTIGEN/repos

# clone antigen if not present
if [[ ! -f $ANTIGEN/antigen.zsh ]]; then
    git clone --recursive https://github.com/zsh-users/antigen $ANTIGEN
    source $ANTIGEN/antigen.zsh
    source ~/.antigenrc
fi

# Install
#cd $PLUGIN_DIR

# find the installers and run them iteratively
#find . -name "install" | while read installer ; do sh -c "${installer}" ; done
