#!/usr/bin/env bash

set -e -x

#Install nvm
if [ ! -d "$HOME/.nvm" ];then
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
