#!/usr/bin/env bash
sudo virt-install --name cka-cp01 --os-variant ubuntu20.04 --vcpus 4 --ram 4096 --location http://ftp.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/ --network bridge=virbr0,model=virtio --graphics none --extra-args='console=ttyS0,115200n8 serial'
