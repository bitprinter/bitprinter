#!/bin/bash -e

DEBOOTSTRAP_DIR=$1
CONFIG_FILE=$2

cp "$CONFIG_FILE" "$DEBOOTSTRAP_DIR/rootfs/root/"
chroot "$DEBOOTSTRAP_DIR/rootfs/" /root/config.sh

exit 0
