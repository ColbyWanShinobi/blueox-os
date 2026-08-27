#! /bin/bash

cat /etc/sub?id

echo "${USER}:100000:1000854465" | sudo tee /etc/subuid
echo "${USER}:100000:1000854465" | sudo tee /etc/subgid

cat /etc/sub?id

podman system migrate
sudo setsebool -P container_use_devices=true
