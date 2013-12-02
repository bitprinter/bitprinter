#!/bin/bash

DEBOOTSTRAP_DIR=$1
CONFIG_FILE=$2

source "$CONFIG_FILE"

# Set a root password for your device...
chroot "$DEBOOTSTRAP_DIR/rootfs/" /usr/bin/passwd

exit 0
