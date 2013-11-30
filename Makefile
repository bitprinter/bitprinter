SHELL=/bin/sh
MAJOR_VERSION=0
MINOR_VERSION=1
IMAGE_SIZE=1000

# Debian Mirror (change this for local mirror or other base)
DEB_MIRROR="http://archive.raspbian.org/raspbian/"


# Create a bootable bitprinter image for Raspberry Pi
#
# This will work best on Debian or Debian-like distros.
#
# Depends: qemu, qemu-user, qemu-user-static, binfmt-support, git, debootstrap


# Referenced directories
BUILD_DIR=./build
DEBOOTSTRAP_DIR=$(BUILD_DIR)/debootstrap
FIRMWARE_DIR=./lib/firmware
MOUNT_DIR=$(BUILD_DIR)/mnt

# Name of created image
DATE=$(shell date "+%s")
IMAGE=$(BUILD_DIR)/bitprinter-$(DATE)-SHA1.img

all: configure-root configure-boot image unmount sha

clean:
	rm -rf $(BUILD_DIR)/*

debootstrap-empty:
	mkdir -p $(DEBOOTSTRAP_DIR)

debootstrap: debootstrap-empty
	@echo "Bootstrapping stage 1 ..."

	cd $(DEBOOTSTRAP_DIR)
	rm -rf ./rootfs
	debootstrap \
		--foreign \
		--no-check-gpg --include=ca-certificates \
		--arch=armhf \
		testing \
		rootfs \
		$(DEB_MIRROR)
	cd $(BUILD_DIR)

	@echo "Bootstrapping stage 2 ..."
	EXTRA_OPTS="-L/usr/lib/arm-linux-gnueabihf"
	cp $(shell which qemu-arm-static) $(DEBOOTSTRAP_DIR)/rootfs/usr/bin/
	chroot $(DEBOOTSTRAP_DIR)/rootfs/ /debootstrap/debootstrap --second-stage --verbose

configure-root: debootstrap
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

configure-boot: debootstrap-empty
	mkdir -p $(DEBOOTSTRAP_DIR)/bootfs
	cp -R $(FIRMWARE_DIR)/boot/* $(DEBOOTSTRAP_DIR)/bootfs/

empty-image:
	@echo "Creating an empty image ..."
	dd if=/dev/zero of=$(IMAGE) bs=1M count=$(IMAGE_SIZE)

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

loop: disk
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

format: loop
	# Format partitions
	mkfs.vfat $(BOOTP)
	mkfs.ext4 $(ROOTP)

mount: format
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
