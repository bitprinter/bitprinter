#!/bin/bash -e

# Helper to create, partition and format a disk for raspberry pi

IMAGE=$1
MOUNT_DIR=$2

DEVICE=`losetup -f --show $IMAGE`
echo "DEVICE: $DEVICE"

# Ignore errors/warnings in fdisk
set +e

# n(ew), p(artition), 1, (default offset), +64MB (boot), t(ype), c (vfat)
# n(ew), p(artition), 2, (default offset), (default size)
# w(rite)
{
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
} # > /dev/null 2>&1

# Run setup on the formatted loop device
echo "Deleting loop: $DEVICE ..."
losetup -d $DEVICE

# Turn error checking back on
set -e

# Add mappings for our new device and store the output for mounting
echo "Running kpartx ..."
PARTS=`kpartx -va $IMAGE | cut -d ' ' -f 3`
PART_BOOT=`echo "$PARTS" | head -n 1`
PART_ROOT=`echo "$PARTS" | tail -n 1`

# Construct new boot/root partition devices
MAPPER=/dev/mapper
BOOTP=$MAPPER/$PART_BOOT
ROOTP=$MAPPER/$PART_ROOT
echo "Boot partition mapped to: $BOOTP"
echo "Root partition mapped to: $ROOTP"

# Format partitions
echo "Formatting partitions ..."
mkfs.vfat $BOOTP
mkfs.ext4 $ROOTP

# Make temporary mnt directory and mount image
echo "Mounting partitions ..."
mkdir -p $MOUNT_DIR
mount $ROOTP $MOUNT_DIR

mkdir -p $MOUNT_DIR/boot
mount $BOOTP $MOUNT_DIR/boot

echo "Done!"
