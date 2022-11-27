#!/usr/bin/env bash

wget http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-disk-kvm.img
qemu-img info focal-server-cloudimg-amd64-disk-kvm.img
read -p "Confirm the image is qcow2... [ENTER]"
sudo mv focal-server-cloudimg-amd64-disk-kvm.img /var/lib/libvirt/images/

sudo exa /var/lib/libvirt/images/

exit 0
