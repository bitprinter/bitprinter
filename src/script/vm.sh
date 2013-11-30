#!/bin/bash

# Small helper to run bitprinter images in QEMU

KERNEL=lib/firmware/boot/kernel.img
qemu-system-arm \
 -kernel "$KERNEL" \
 -cpu arm1176 \
 -m 256 \
 -M versatilepb \
 -no-reboot \
 -serial stdio \
 -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
  -hda "$1"

