#!/usr/bin/env bash

set -e -x

mkdir -p ${HOME}/.local/bin
#Install YouTube Download
if [ ! -x "$(command -v yt-dlp)" ];then
  wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O ${HOME}/.local/bin/yt-dlp
  chmod a+rx ${HOME}/.local/bin/yt-dlp  # Make executable
fi
#sudo apt install -y ffmpeg
