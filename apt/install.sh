#!/usr/bin/env bash
#
# dotphiles : https://github.com/dotphiles/dotphiles
#
# Script to bootstrap a linux box
#
# Authors:
#   Ben O'Hara <bohara@gmail.com>
#

DIR=$(cd $(dirname "$0"); pwd)

echo "DIR = $DIR"

if [[ -f $DIR/list_packets ]]; then
  exec<$DIR/list_packets
  while read line
  do
    if [[ ! "$line" =~ (^#|^$) ]]; then
      packages="$packages $line"
    fi
  done
  sudo apt-get -y install $packages
fi
