#!/bin/bash

sudo virsh list --all
sudo virsh console $1
