#!/usr/bin/env bash

SCRIPT_NAME=$(basename $0)
SCRIPT_PATH=$(dirname $(readlink -f $0))
SCRIPT="${SCRIPT_PATH}/${SCRIPT_NAME}"

# # # CONFIG


HOSTS=($1)
#HOSTS=(c1 n1 n2 n3)

VCPU=2
RAM=4096
DISKGB=80
USERID=dustin
# NTWK="nat"
NTWK="bridged"
# DHCP only applies in bidged mode
# DHCP="no"
DHCP="yes"
# Only used id DHCP="no"
# STATICIPS=(192.168.168.5 192.168.168.1 192.168.168.2 192.168.168.3)


# Set Colours
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
TEAL=$(tput setaf 14)
NC=$(tput sgr0)

# Define script dependencies
# neededSoftware=(git ansible)

# # Check if software is installed and install with APT if needed
# function checkInstalled() {
#     dpkg -s "$1" 2>/dev/null >/dev/null || sudo apt -y install "$1"
# }

function printYellow() {
    # Used http://shapecatcher.com/ to get the unicode
    printf "$GREEN \u2799 $NC %1s \n" "$YELLOW $1 $NC"
}

function printGreen() {
    # Used http://shapecatcher.com/ to get the unicode
    printf "$YELLOW \u2799 $NC %1s \n" "$GREEN $1 $NC"
}

function printTitle() {
    echo
    # Used http://shapecatcher.com/ to get the unicode
    printf "$TEAL \u232a\u232a\u232a $NC %1s \n" "$TEAL $1 $NC"
    echo
}

function showDone() {
    printf "$GREEN \u2713  %1s\n" "Done $NC"
}

function showFail() {
    printf "$RED \u2694 %1s \n" "Failed $NC"
    exit 1
}

function testEcho() {
    printf "$RED \u2694 %1s \n" " $1: $2 - [TESTING] $NC"
    exit 1
}

# Check if we need to edit the host names

clear

printTitle "checking hosts"
printYellow "Current hosts:"
echo
cat ${SCRIPT} | grep "HOSTS=" | grep -v "#HOSTS" | grep -v "cat"
echo
while true
do
 read -r -p "--> Do you need to edit the hosts? [Y/n] " input

 case $input in
     [yY][eE][sS]|[yY])
 printYellow "opening file for editing..."
 nano ${SCRIPT}
 break
 ;;
     [nN][oO]|[nN])
 printYellow "skipping edit."
 break
        ;;
     *)
 echo "Invalid input..."
 ;;
 esac
done



# Loop and create each host
for i in ${!HOSTS[@]}; do

# Array indexes match
HOST=${HOSTS[$i]}
STATICIP=${STATICIPS[$i]}

clear

# Generate random MAC to use
# For KVM VMs it is required that the first 3 pairs in the MAC address be the sequence 52:54:00:
printTitle "generating random KVM MAC address"
export MAC_ADDR=$(printf '52:54:00:%02x:%02x:%02x' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
showDone


export DOM=mylo
export IMAGE_FLDR="/var/lib/libvirt/images"
export WRK_FLDR="/home/dustin/kvm/base"
# Go to work dir
cd ${WRK_FLDR}

printTitle "creating disk"
# Create the disk
sudo qemu-img create -F qcow2 -b ${WRK_FLDR}/focal-server-cloudimg-amd64.img -f qcow2 ${IMAGE_FLDR}/${HOST}.qcow2 ${DISKGB}G
showDone

printTitle "creating network-config"
# Config network with cloud-init


if [ "$DHCP" = "no" ]; then
# Create network-config to set a static address
cat >network-config <<EOFSTATIC
ethernets:
    all:
        addresses:
        - ${STATICIP}/20
        dhcp4: false
        gateway4: 192.168.169.1
        match:
            name: en*
        nameservers:
            search: [mylo]
            addresses:
            - 192.168.168.2
version: 2
EOFSTATIC
# Create network-config to use a DHCP address
# for a bridged or nat interface
elif [ "$DHCP" = "yes" ] || [ "$NTWK" = "nat" ] ; then

cat >network-config <<EOFDHCP
ethernets:
    all:
        dhcp4: true
        match:
            name: en*
        nameservers:
            search: [mylo]
            addresses:
            - 192.168.168.2
version: 2
EOFDHCP

else
    printYellow "Could not create network-config file"
    showFail
    exit 1
fi

showDone

# Main cloud-init

# ip -4 addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}'

printTitle "creating user-data"
cat >user-data <<EOFU
#cloud-config

## Set Hostname
hostname: ${HOST}
fqdn: ${HOST}.${DOM}
manage_etc_hosts: true

# Enable password authentication with the SSH daemon
ssh_pwauth: true
disable_root: false

## Install additional packages on first boot
packages:
- zsh
- curl
- tmux
- vim-nox
- qemu-guest-agent

users:
  - name: ${USERID}
    gecos: ${USERID}
    primary_group: ${USERID}
    groups: users, admin, sudo
    shell: /usr/bin/zsh
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCi1ukcZU9jVoqmn9+acVwExfw24vAZ53HyQh3VT9aXRYKhLbfMOU2tvRlgIX+znOE4Uc3goFhRB/Qes/NchS6IQf2lfbHBUXoVtzl2gxMfMh49lecoYsv24NtnBLw9QGv/HfhqBR/8ZZbI3vE2XPEEyJDZDTl96iimX/DvxIjRoFowQtfhe4S5zYK7Km6RMEOCWLEt7FApIs1oezylUgGb4k0SAJTOWUT9It8j0BX7ydvPlvKWrJQsVpgw54iyDNj9GiM8qNIt/ziWEAmFj/sqW80lngkXyDJymyan31ijlDvoksEQY+e7BqzA+6IEu0QUCD55NO8ewaRZFTtUTGLIxND/FIR/jir0II0Qnoq4iJWIWls/2G51cKUjc0nkdD+qjXcdaHVJj/1mMxAq7iUWj9RPkKWllYKIV6m1vZV9rBWY++O8JBeSZKofIydNDyUUyx+YCmSOICDYQ2Y0H2W10b+K08OlFeHzzrppePnCN5xw8VlDbhxDLxREJ6t6lYwi1cWOMZ6pj4yJ3i+HcsJVw7V8IB+/QVKmD8SWNi3Ez6He9Thhq4HiqnKOA2FvakClQUZHOuCtT9HQbSOn+30oeF2WHZugpnEaH8hTx1yyyrSzPncc+QbYsxs49w1AREOjZIRUbY5dR4ljx7WxII735yGPCELPBoZIvre/rAr4Jw== dustin@bashfulrobot.com
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
# Set user password
chpasswd:
    list: |
        ${USERID}:${USERID}
    expire: false
## Update apt database and upgrade packages on first boot
package_update: true
package_upgrade: true

runcmd:
 - [ systemctl, start, qemu-guest-agent ]

# written to /var/log/cloud-init-output.log in VM
final_message: "W00T, We should be up and ready after $UPTIME seconds at $TIMESTAMP"
EOFU
showDone

# Create meta-data
printTitle "creating meta-data"
touch meta-data
showDone

# Create seed image
printTitle "creating seed image"
if [ "$NTWK" = "bridged" ]; then
        # Import network-config for bridged interfaces
        sudo cloud-localds -v --network-config=network-config ${IMAGE_FLDR}/${HOST}-seed.qcow2 user-data meta-data
elif [ "$NTWK" = "nat" ]; then
        # Skip the network-config file and let KVM do the default NAT
        sudo cloud-localds -v ${IMAGE_FLDR}/${HOST}-seed.qcow2 user-data meta-data
else
        printYellow "Seed image not created. Failed cloud-localds."
        showFail
        exit 1
fi

showDone

# Ensure images have the proper permissions
printTitle "fixing permissions"
sudo chown -R libvirt-qemu:kvm ${IMAGE_FLDR}
showDone

# Create VM


printTitle "creating vm"

case ${NTWK} in
    bridged)
        # bridged network
        sudo virt-install --virt-type kvm --name ${HOST} --ram ${RAM} --vcpus=${VCPU} --os-type linux --os-variant ubuntu20.04 --disk path=${IMAGE_FLDR}/${HOST}.qcow2,device=disk --disk path=${IMAGE_FLDR}/${HOST}-seed.qcow2,device=disk --graphics=vnc --import --network bridge=br0,model=virtio,mac=${MAC_ADDR} --noautoconsole
        ;;
    nat)
        # nat network
        sudo virt-install --virt-type kvm --name ${HOST} --ram ${RAM} --vcpus=${VCPU} --os-type linux --os-variant ubuntu20.04 --disk path=${IMAGE_FLDR}/${HOST}.qcow2,device=disk --disk path=${IMAGE_FLDR}/${HOST}-seed.qcow2,device=disk --graphics=vnc --import --network network=default,model=virtio,mac=${MAC_ADDR} --noautoconsole
        ;;
    *)
        printYellow "Your network has an error. Failed virt-install."
        showFail
        exit 1
        ;;
esac


showDone

printTitle "cleaning up"
sudo rm -f ${WRK_FLDR}/network-config
sudo rm -f ${WRK_FLDR}/user-data
sudo rm -f ${WRK_FLDR}/meta-data
showDone

# get guest IP
printTitle "Waiting for cloud-init to finish"
printYellow "waiting for qemu-agent to get IP..."

until sudo virsh domifaddr --source agent ${HOST} > /dev/null 2>&1
do
    printYellow "waiting for qemu-agent to get IP..."
    sleep 20
done

MYIP=$(sudo virsh domifaddr --source agent "${HOST}" | grep -e 10.0 -e 192. | cut -d " " -f20)

MYIP2=$(sudo virsh domifaddr --source agent "${HOST}" | grep -e 10.0 -e 192. | cut -d " " -f20 | cut -d "/" -f1)
telegram-send "success! ${HOST} vm has been deployed on: ${MYIP}."

showDone
"success! ${HOST} vm has been deployed on: ${MYIP}."

echo "Host ${HOST}" >> ssh-cfg
echo "HostName ${MYIP2}" >> ssh-cfg
echo "# ProxyJump srv" >> ssh-cfg
echo "User dustin" >> ssh-cfg
echo "AddKeysToAgent yes" >> ssh-cfg
echo "IdentityFile ~/.ssh/id_rsa" >> ssh-cfg
echo >> ssh-cfg

# End host loop
done

cat ssh-cfg
rm -f ssh-cfg
