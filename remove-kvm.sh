#!/usr/bin/env bash

# Update the system
sudo apt update
sudo apt dist-upgrade -y
# Install KVM
sudo apt -y purge libvirt-clients libvirt-daemon-system qemu-kvm -y
# Install virt-install
sudo apt purge virtinst -y
# Auto remove
sudo apt autoremove -y
exit 0
