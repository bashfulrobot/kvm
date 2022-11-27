#!/usr/bin/env bash

# Update the system
sudo apt update
sudo apt dist-upgrade -y
# Install KVM
sudo apt -y install bridge-utils cpu-checker libvirt-clients libvirt-daemon-system qemu-kvm -y
# Start libvirtd
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo systemctl status libvirtd
sleep 3
sudo virsh net-autostart --network default
# Install virt-install
sudo apt install virtinst -y
# Install cloud image utils and nmap
sudo apt install cloud-image-utils nmap -y
# Add user to the KVM/libvirt groups
sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER
sudo usermod -aG libvirt-qemu $USER
# Start the default network - needed for virbr0
sudo virsh net-start --network default
# Does the system support KVM?
kvm-ok

exit 0
