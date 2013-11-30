SHELL=/bin/sh
MAJOR_V=0
MINOR_V=1
IMAGE_SIZE=100

# Debian Mirror (change this for local mirror or other base)
DEB_MIRROR="http://archive.raspbian.org/raspbian/"


# Create a bootable bitprinter image for Raspberry Pi
#
# This is a rather abusive/hacky way to use `make`. We are not compiling
# and most of this will need to be done as root. However, it does provide
# a very convenient and familiar interface for getting the job done.
#
# In order to save time during development, debootstrap is not run every build.
# Instead, run `make debootstrap-sync` when you wish to do a full network
# update and copy the results into lib/debootstrap. Everything else will just
# use copies lib/debootstrap.
#
# Targets:
#  clean -- Clear out build directory
#  distclean -- Clear out release directory
#  debootstrap-sync -- Synchronize lib/debootstrap with latest found in mirror
#  all -- Build a new image (used cached copy in lib/debootstrap)
#
# Depends: qemu, qemu-user, qemu-user-static, binfmt-support, git, debootstrap


# Referenced directories
BUILD_DIR=./build
DEBOOTSTRAP_PARENT=./lib/debootstrap
DEBOOTSTRAP_DIR=$(BUILD_DIR)/debootstrap
FIRMWARE_DIR=./lib/firmware
MOUNT_DIR=$(BUILD_DIR)/mnt
SCRIPT_DIR=./src/script
RELEASE_DIR=./release

# Name of created image
DATE=$(shell date "+%s")
#IMAGE=$(BUILD_DIR)/bitprinter-$(DATE)-SHA1.img

# Experiment with same working name every time
IMAGE_NAME=bitprinter
IMAGE_EXT=img
IMAGE=$(BUILD_DIR)/$(IMAGE_NAME).$(IMAGE_EXT)

all: root boot image unmount dist

clean:
	rm -rf $(BUILD_DIR)/*

distclean:
	rm -rf $(RELEASE_DIR)/*

debootstrap-clean:
	rm -rf $(DEBOOTSTRAP_DIR)

debootstrap-empty:
	mkdir -p $(DEBOOTSTRAP_DIR)

debootstrap: debootstrap-clean debootstrap-empty
	cp -R $(DEBOOTSTRAP_PARENT)/rootfs $(DEBOOTSTRAP_DIR)/rootfs

debootstrap-sync:
	# Bootstrap stage 1 ...
	mkdir -p $(DEBOOTSTRAP_PARENT)
	cd $(DEBOOTSTRAP_PARENT)
	rm -rf $(DEBOOTSTRAP_PARENT)/rootfs
	debootstrap \
		--foreign \
		--no-check-gpg --include=ca-certificates \
		--arch=armhf \
		testing \
		$(DEBOOTSTRAP_PARENT)/rootfs \
		$(DEB_MIRROR)

	# Bootstrap stage 2 ...
	EXTRA_OPTS="-L/usr/lib/arm-linux-gnueabihf"
	cp $(shell which qemu-arm-static) $(DEBOOTSTRAP_PARENT)/rootfs/usr/bin/
	chroot $(DEBOOTSTRAP_PARENT)/rootfs/ /debootstrap/debootstrap --second-stage --verbose

root: debootstrap
	# Running setup and configuration ...

	# Copy hard-float firmare into our rootfs
	cp -R $(FIRMWARE_DIR)/hardfp/opt/* $(DEBOOTSTRAP_DIR)/rootfs/opt/

	# Copy over pre-compiled modules for Raspberry Pi
	cp -R $(FIRMWARE_DIR)/modules/* $(DEBOOTSTRAP_DIR)/rootfs/lib/modules/

	# TODO: Add additional config here

	# Set a root password for your device...
	chroot $(DEBOOTSTRAP_DIR)/rootfs/ /usr/bin/passwd

	# Clean up emulation binaries
	rm $(DEBOOTSTRAP_DIR)/rootfs/usr/bin/qemu-arm-static

boot: debootstrap-empty
	mkdir -p $(DEBOOTSTRAP_DIR)/bootfs
	cp -R $(FIRMWARE_DIR)/boot/* $(DEBOOTSTRAP_DIR)/bootfs/

empty-image:
	# Create an empty image ...
	dd if=/dev/zero of=$(IMAGE) bs=1M count=$(IMAGE_SIZE)

disk: empty-image
	# Write partition table
	$(SCRIPT_DIR)/partition.sh $(IMAGE)

find-loop: disk
	# Add mappings for our new device and store the output for mounting
	PARTS=$(shell kpartx -va $(IMAGE) | cut -d ' ' -f 3)
	PART1=$(shell echo $(PARTS) | head -n 1)
	PART2=$(shell echo $(PARTS) | tail -n 1)

	# Construct new boot/root partition devices
	MAPPER=/dev/mapper
	BOOTP=$(MAPPER)$(PART1)
	ROOTP=$(MAPPER)$(PART2)

format: find-loop
	# Format partitions
	mkfs.vfat $(BOOTP)
	mkfs.ext4 $(ROOTP)

mount: format
	# Make temporary mnt directory and mount image
	mkdir -p $(MOUNT_DIR)
	mount $(ROOTP) $(MOUNT_DIR)

	mkdir -p $(MOUNT_DIR)/boot
	mount $(BOOTP) $(MOUNT_DIR)/boot

image: root boot mount
	# Copy the output of debootstrap into the image
	cp -r $(DEBOOTSTRAP_DIR)/rootfs/* $(MOUNT_DIR)/
	cp -r $(DEBOOTSTRAP_DIR)/bootfs/* $(MOUNT_DIR)/boot/

unmount:
	# Unmount the image and remove temporary mount point
	umount $(MOUNT_DIR)/boot
	umount $(MOUNT_DIR)

	# Remove mappings to image
	kpartx -d $(IMAGE)

	# Remove mount point
	rm -rf $(MOUNT_DIR)

dist:
	$(SCRIPT_DIR)/release.sh $(IMAGE) $(MAJOR_V).$(MINOR_V) $(RELEASE_DIR)
