# Bugtracker

This document tracks known issues and bugs in the project

## Ansible Controller

The controller VM can hang after a `tofu destroy` has been run. Can require running `VBoxManage controlvm "Ansible-Controller" poweroff`.

The controller VM sometimes hangs the `vboxadd-service` currently requires manual reboot `restart vboxadd-service`.
