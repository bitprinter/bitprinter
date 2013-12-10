#!/bin/bash

# Install bitprinter build dependencies
apt-get -y install qemu qemu-user qemu-user-static binfmt-support
apt-get -y install dosfstools e2fsprogs kpartx debootstrap

# Run debootstrap-sync so we have a fresh copy to work with
cd /vagrant
sudo make debootstrap-sync
