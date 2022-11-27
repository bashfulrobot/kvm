#!/usr/bin/env bash

MAC=$(virsh domiflist $1 | awk '{ print $5 }' | tail -2 | head -1)

arp -a | grep ${MAC} | awk '{ print $2 }' | sed 's/[()]//g'
