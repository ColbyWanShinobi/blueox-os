#!/usr/bin/env bash

# Run this after creating the desktop user if it lacks subordinate ID mappings.
echo "${USER}:100000:1000854465" | sudo tee /etc/subuid
echo "${USER}:100000:1000854465" | sudo tee /etc/subgid
