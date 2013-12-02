#!/bin/bash

DEBOOTSTRAP_DIR=$1
CONFIG_FILE=$2

source "$2"
# TODO: Add additional config here

# Set a root password for your device...
chroot "$DEBOOTSTRAP_DIR/rootfs/" /usr/bin/passwd

exit 0
