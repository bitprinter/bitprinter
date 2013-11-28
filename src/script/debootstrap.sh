#!/bin/bash

# Depends: qemu, qemu-user, qemu-static, binfmt-support, git, debootstrap
# qemu package names may vary by distro

# Bootstrap the initial system in whichever directory we are in
sudo debootstrap \
 --foreign \
 --no-check-gpg --include=ca-certificates \
 --arch=armhf \
 testing \
 rootfs \
 http://archive.raspbian.org/raspbian/

