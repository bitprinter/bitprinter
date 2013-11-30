#!/bin/bash -e

# Helper to partition disk for raspberry pi

DEVICE=`losetup -f --show $1`
echo "DEVICE: $DEVICE"
# n(ew), p(artition), 1, (default offset), +64MB (boot), t(ype), c (vfat)
# n(ew), p(artition), 2, (default offset), (default size)
# w(rite)
fdisk $DEVICE << EOF
n
p
1

+64M
t
c
n
p
2


w
EOF

# Run setup on the formatted loop device
losetup -d $DEVICE
