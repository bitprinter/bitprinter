SHELL=/bin/sh
MAJOR_VERSION=0
MINOR_VERSION=1

# Create a bootable bitprinter image for Raspberry Pi

# This script is tested on Debian and Debian-based distros. The process
# should be similar in other environments but may need some additional steps.

# Depends: qemu, qemu-user, qemu-user-static, binfmt-support, git, debootstrap

# Note Nov. 28, 2013 - Issues running in Arch Linux due to binfmt-support.


## Globals

# Referenced directories
BUILD_DIR=./build
DEBOOTSTRAP_DIR=$(BUILD_DIR)/debootstrap
FIRMWARE_DIR=./lib/firmware
MOUNT_DIR=$(BUILD_DIR)/mnt

# Debian Mirror (change this for local mirror or other base)
DEB_MIRROR="http://archive.raspbian.org/raspbian/"

# Name of created image
DATE=$(shell date "+%s")
IMAGE=$(BUILD_DIR)/bitprinter-$(DATE)-SHA1.img

all: setup configure-root configure-boot image unmount sha

clean:
	rm -rf $(BUILD_DIR)

setup:
	@echo "Building into: $(IMAGE)"
	@mkdir -p $(BUILD_DIR)

stage1-clean: setup
	rm -rf $(DEBOOTSTRAP_DIR)
	mkdir $(DEBOOTSTRAP_DIR)

stage1: stage1-clean
	@echo "Bootstrapping stage 1 ..."
	cd $(DEBOOTSTRAP_DIR)
	debootstrap \
		--foreign \
		--no-check-gpg --include=ca-certificates \
		--arch=armhf \
		testing \
		rootfs \
		$(DEB_MIRROR)
	cd $(BUILD_DIR)

stage2: stage1
	@echo "Bootstrapping stage 2 ..."
	EXTRA_OPTS="-L/usr/lib/arm-linux-gnueabihf"
	cp $(shell which qemu-arm-static) $(DEBOOTSTRAP_DIR)/rootfs/usr/bin/
	chroot $(DEBOOTSTRAP_DIR)/rootfs/ /debootstrap/debootstrap --second-stage --verbose

configure-root: stage2
	@echo "Running setup and configuration ..."

	# Copy hard-float firmare into our rootfs
	cp -R $(FIRMWARE_DIR)/hardfp/opt/* $(DEBOOTSTRAP_DIR)/rootfs/opt/

	# Copy over pre-compiled modules for Raspberry Pi
	cp -R $(FIRMWARE_DIR)/modules/* $(DEBOOTSTRAP_DIR)/rootfs/lib/modules/

	# TODO: Add additional config here

	@echo "Set a root password for your device..."
	chroot $(DEBOOTSTRAP_DIR)/rootfs/ /usr/bin/passwd

	# Clean up emulation binaries
	rm $(DEBOOTSTRAP_DIR)/rootfs/usr/bin/qemu-arm-static

configure-boot: stage2
	mkdir -p $(DEBOOTSTRAP_DIR)/bootfs
	cp -R $(FIRMWARE_DIR)/boot/* $(DEBOOTSTRAP_DIR)/bootfs/

empty-image: setup
	@echo "Creating an empty image ..."
	dd if=/dev/zero of=$(IMAGE) bs=1M count=1000

disk: empty-image
	@echo "Writing partition table"
	DEVICE=$(shell losetup -f --show $(IMAGE))

	# n(ew), p(artition), 1, (default offset), +64MB (boot), t(ype), c (vfat)
	# n(ew), p(artition), 2, (default offset), (default size)
	# w(rite)
	fdisk $(DEVICE) << EOF
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
	losetup -d $(DEVICE)

	# Add mappings for our new device and store the output for mounting
	PARTS=$(shell kpartx -va $(IMAGE) | cut -d ' ' -f 3)
	PART1=$(shell echo $(PARTS) | head -n 1)
	PART2=$(shell echo $(PARTS) | tail -n 1)

	# Construct new boot/root partition devices
	MAPPER=/dev/mapper
	BOOTP=$(MAPPER)$(PART1)
	ROOTP=$(MAPPER)$(PART2)

	# Format partitions
	mkfs.vfat $(BOOTP)
	mkfs.ext4 $(ROOTP)

mount: disk
	# Make temporary mnt directory and mount image
	mkdir -p $(MOUNT_DIR)
	mount $(ROOTP) $(MOUNT_DIR)

	mkdir -p $(MOUNT_DIR)/boot
	mount $(BOOTP) $(MOUNT_DIR)/boot

image: configure-root configure-boot mount
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

sha:
	echo "Compute SHA1 ..."

	SHA=`sha1sum $(IMAGE) | cut -d ' ' -f 1`
	echo "SHA1: $(SHA)"

	rename "s/SHA1/SHA1\-$(SHA)/" $(IMAGE)
