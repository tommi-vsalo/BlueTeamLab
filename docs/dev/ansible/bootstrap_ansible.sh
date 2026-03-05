#!/usr/bin/env bash
set -euo pipefail

# Creates:
#   ~/ansible-controller/
#     inventory/
#     playbooks/
# Installs Ansible if missing.

PROJECT_DIR="$HOME/ansible-controller"
INVENTORY_DIR="$PROJECT_DIR/inventory"
PLAYBOOKS_DIR="$PROJECT_DIR/playbooks"

need_cmd() { command -v "$1" >/dev/null 2>&1; }

echo "==> Creating Ansible controller directories in: $PROJECT_DIR"
mkdir -p "$INVENTORY_DIR" "$PLAYBOOKS_DIR"

echo "==> Installing Ansible (if not installed)..."
if need_cmd ansible; then
  echo "    Ansible already installed: $(ansible --version | head -n1)"
else
  if need_cmd apt-get; then
    sudo apt-get update -y
    sudo apt-get install -y ansible
  elif need_cmd dnf; then
    sudo dnf install -y ansible
  elif need_cmd yum; then
    sudo yum install -y ansible
  elif need_cmd pacman; then
    sudo pacman -Sy --noconfirm ansible
  elif need_cmd zypper; then
    sudo zypper refresh
    sudo zypper install -y ansible
  else
    echo "ERROR: Could not detect a supported package manager (apt/dnf/yum/pacman/zypper)."
    echo "Install Ansible manually, then re-run this script."
    exit 1
  fi
fi

echo
echo "==> Done!"
echo "Created:"
echo "  $PROJECT_DIR/"
echo "    inventory/"
echo "    playbooks/"
echo
echo "Next (create files manually):"
echo "  nano $INVENTORY_DIR/hosts.ini"
echo "  nano $PLAYBOOKS_DIR/setup.yml"
