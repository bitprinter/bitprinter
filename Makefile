SHELL=/bin/sh
MAJOR_V=0
MINOR_V=1
IMAGE_SIZE=500

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
#  emulator -- Launch QEMU with the most recent release
#
# Depends: qemu, qemu-user, qemu-user-static, binfmt-support, kpartx, debootstrap


# Referenced directories
BUILD_DIR=./build
DEBOOTSTRAP_PARENT=./lib/debootstrap
DEBOOTSTRAP_DIR=$(BUILD_DIR)/debootstrap
FIRMWARE_DIR=./lib/firmware
MOUNT_DIR=$(BUILD_DIR)/mnt
SCRIPT_DIR=./src/script
STAGING_DIR=./staging

# Working name for image (pre-release)
IMAGE_NAME=bitprinter
IMAGE_EXT=img
IMAGE=$(BUILD_DIR)/$(IMAGE_NAME).$(IMAGE_EXT)

all: root boot image unmount dist

delete-map:
	# Remove mappings to image
	kpartx -d $(IMAGE)

clean: delete-map
	rm -rf $(BUILD_DIR)/*

distclean:
	rm -rf $(STAGING_DIR)/*.img

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

	# Run bitprinter customization script
	$(SCRIPT_DIR)/customize.sh $(DEBOOTSTRAP_DIR)

	# Clean up emulation binaries
	rm $(DEBOOTSTRAP_DIR)/rootfs/usr/bin/qemu-arm-static

boot: debootstrap-empty
	mkdir -p $(DEBOOTSTRAP_DIR)/bootfs
	cp -R $(FIRMWARE_DIR)/boot/* $(DEBOOTSTRAP_DIR)/bootfs/

empty-image:
	# Create an empty image ...
	dd if=/dev/zero of=$(IMAGE) bs=1M count=$(IMAGE_SIZE)

disk: empty-image
	# Handle creation, partitioning, formatting and mounting a new disk
	$(SCRIPT_DIR)/disk.sh $(IMAGE) $(MOUNT_DIR)

image: root boot disk
	# Copy the output of debootstrap into the image
	cp -r $(DEBOOTSTRAP_DIR)/rootfs/* $(MOUNT_DIR)/
	cp -r $(DEBOOTSTRAP_DIR)/bootfs/* $(MOUNT_DIR)/boot/

unmount:
	# Unmount the image and remove temporary mount point
	umount $(MOUNT_DIR)/boot
	umount $(MOUNT_DIR)

	# Remove mount point
	rm -rf $(MOUNT_DIR)

dist:
	$(SCRIPT_DIR)/release.sh $(IMAGE) $(MAJOR_V).$(MINOR_V) $(STAGING_DIR)

emulator:
	# Launch an emulator with the latest release
	qemu-system-arm \
	 -kernel ./lib/kernel-qemu \
	 -cpu arm1176 \
	 -m 256 \
	 -M versatilepb \
	 -no-reboot \
	 -serial stdio \
	 -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
	 -hda $(shell ls -st release/*.img | head -n 1 | cut -d ' ' -f 2)
