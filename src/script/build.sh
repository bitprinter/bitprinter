#!/bin/bash -e

# This script will create a bootable image for Raspberry Pi

# This script is only tested on Debian and Debian-based distros. The process
# should be similar in other environments but may need some additional steps.

# Depends: qemu, qemu-user, qemu-user-static, binfmt-support, git, debootstrap

# Note Nov. 28, 2013 - Issues running in Arch Linux due to binfmt-support.


## Globals

# Referenced directories
PWD=`pwd`
BUILD_DIR="$PWD/build"
DEBOOTSTRAP_DIR="$BUILD_DIR/debootstrap"
FIRMWARE_DIR="$PWD/lib/firmware"

# Debian Mirror (change this for local cache or other base)
DEB_MIRROR="http://archive.raspbian.org/raspbian/"

# Name of created image
DATE=`date "+%s"`
IMAGE="bitprinter-$DATE-SHA1.img"


## Initial setup

echo "Building into: $BUILD_DIR/$IMAGE"

# Ensure build dir
mkdir -p "$BUILD_DIR"

## Bootstrap stage 1

# Clean any old debootstrap dir
rm -rf "$DEBOOTSTRAP_DIR"
mkdir "$DEBOOTSTRAP_DIR"

# Bootstrap the initial system
debootstrap \
 --foreign \
 --no-check-gpg --include=ca-certificates \
 --arch=armhf \
 testing \
 rootfs \
 "$DEB_MIRROR"


## Bootstrap stage 2

# Ensure we build with hard-float support
EXTRA_OPTS="-L/usr/lib/arm-linux-gnueabihf"

# Copy static arm emulation binaries so we can run inside chroot
cp $(which qemu-arm-static) rootfs/usr/bin/

# Chroot in and bootstrap to second stage
chroot rootfs/ /debootstrap/debootstrap --second-stage --verbose


## Raspberry Pi setup and configuration

# Copy hard-float firmare into our rootfs
cp -R "$FIRMWARE_DIR"/hardfp/opt/* rootfs/opt/

# Finally, set a root password
echo "Set a root password for your device..."
chroot rootfs/ /usr/bin/passwd

# We won't need to run in ARM again so we can clean up our emulation binaries
rm rootfs/usr/bin/qemu-arm-static

# Copy over pre-compiled modules for Raspberry Pi
cp -R "$FIRMWARE_DIR"/modules/* rootfs/lib/modules/

# Set up our boot fs -- this includes a pre-compiled kernel
mkdir -p bootfs
cp -R "$FIRMWARE_DIR"/boot/* bootfs/


## Create empty image

# Move back to base working directory
cd "$BUILD_DIR"

# Write out an empty 1GB image
dd if=/dev/zero of="$IMAGE" bs=1M count=1000


## Format disk

# Setup and store the location of our image
DEVICE=`losetup -f --show "$IMAGE"`

# Format the new disk (ignore errors only in fdisk)
set +e
fdisk "$DEVICE" << EOF
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
set -e

## Write partitions

# Run setup on the formatted loop device
losetup -d "$DEVICE"

# Add mappings for our new device and store the output for mounting
PARTS=`kpartx -va "$IMAGE" | cut -d ' ' -f 3`
PART1=`echo "$PARTS" | head -n 1`
PART2=`echo "$PARTS" | tail -n 1`

# Construct new boot/root partition devices
MAPPER="/dev/mapper"
BOOTP="$MAPPER/$PART1"
ROOTP="$MAPPER/$PART2"

# Make temporary mnt directory
mkdir -p mnt

# Mount the image into the temporary directory
mount "$ROOTP" mnt
mount "$BOOTP" mnt/boot

# Copy the output of debootstrap into the image
cp -r "$DEBOOTSTRAP_DIR"/rootfs/* mnt/
cp -r "$DEBOOTSTRAP_DIR"/bootfs/* mnt/boot/


## Unmount

# Unmount the image
umount mnt/boot
umount mnt


## SHA1
SHA=`sha1sum "$IMAGE"`
rename 's/SHA1/SHA1-$SHA/' "$IMAGE"

echo "Done!"
exit 0

