#!/bin/bash
set -e

echo "Starting Ubuntu bootstrap POC..."

HOSTNAME="ansible-con"
USER= "student"
PASS= "blue"

sudo hostnamectl set-hostname "$HOSTNAME"

sudo apt update
sudo apt install -y openssh-server

cho "Configuring language and keyboard (EN OS / FI keyboard)"

sudo apt install -y locales

sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

sudo sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="fi"/' /etc/default/keyboard
sudo setupcon || true

echo "BOOTSTRAP OK at $(date)" | sudo tee /tmp/bootstrap-status.txt

echo "Ubuntu bootstrap finished!"
