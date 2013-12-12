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
# Host Targets:
#  init -- Helper to get firmware and create build server
#  build -- SSH into Vagrant box and run `make all`
#  emulator -- Launch QEMU with the most recent image
#
# Guest Targets:
#  clean -- Clear out build directory
#  dist-clean -- Remove all images in main bitprinter directory
#  debootstrap-sync -- Synchronize /tmp/debootstrap with latest found in mirror
#  all -- Build a new image (used cached copy in /tmp/debootstrap)
#
# Depends: qemu, qemu-user, qemu-user-static, binfmt-support, kpartx, debootstrap

FIRMWARE_REPO="https://github.com/bitprinter/firmware.git"
BOX=./basebox.json

# Referenced directories
FIRMWARE=./lib/firmware
SCRIPT=./src/script
ASSETS=./assets

# Build Directories
DEBOOTSTRAP_PARENT=/tmp/debootstrap
BUILD=/tmp/build
DEBOOTSTRAP=$(BUILD)/debootstrap
MOUNT=$(BUILD)/mnt

# Working name for image (pre-release)
IMAGE_NAME=bitprinter
IMAGE_EXT=img
IMAGE=$(BUILD)/$(IMAGE_NAME).$(IMAGE_EXT)

# Host make targets
git-firmware:
	if [ ! -d $(FIRMWARE) ] ; then git clone $(FIRMWARE_REPO) $(FIRMWARE) ; fi ;

box:
	packer build $(BOX)

init: git-firmware box

vagrant-up:
	vagrant up

build:
	vagrant ssh -c "cd /vagrant ; sudo make all"

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
	 -hda $(shell ls -st ./*.img | head -n 1 | cut -d ' ' -f 2)

# Guest make targets
all: root boot image unmount dist

delete-map:
	# Remove mappings to image if it exists
	if [ -f $(IMAGE) ] ; then kpartx -d $(IMAGE) ; fi ;

clean: delete-map debootstrap-clean
	rm -rf $(BUILD)/*

dist-clean:
	rm -rf ./*.img

debootstrap-clean:
	rm -rf $(DEBOOTSTRAP)

debootstrap-empty:
	mkdir -p $(DEBOOTSTRAP)

debootstrap: debootstrap-clean debootstrap-empty
	cp -r $(DEBOOTSTRAP_PARENT)/rootfs $(DEBOOTSTRAP)/rootfs

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
	cp -r $(FIRMWARE)/hardfp/opt/* $(DEBOOTSTRAP)/rootfs/opt/

	# Copy over pre-compiled modules for Raspberry Pi
	cp -r $(FIRMWARE)/modules/* $(DEBOOTSTRAP)/rootfs/lib/modules/

	# Copy bitprinter specific assets
	cp -r $(ASSETS)/rootfs/* $(DEBOOTSTRAP)/rootfs/

	# Run bitprinter config script
	cp $(SCRIPT)/config.sh $(DEBOOTSTRAP)/rootfs/root/
	chroot $(DEBOOTSTRAP)/rootfs/ /root/config.sh

	# Clean up emulation binaries
	rm $(DEBOOTSTRAP)/rootfs/usr/bin/qemu-arm-static

boot: debootstrap-empty
	mkdir -p $(DEBOOTSTRAP)/bootfs
	cp -r $(FIRMWARE)/boot/* $(DEBOOTSTRAP)/bootfs/

	# Copy bitprinter specific assets
	cp -r $(ASSETS)/bootfs/* $(DEBOOTSTRAP)/bootfs/

empty-image:
	# Create an empty image ...
	dd if=/dev/zero of=$(IMAGE) bs=1M count=$(IMAGE_SIZE)

disk: empty-image
	# Handle creation, partitioning, formatting and mounting a new disk
	$(SCRIPT)/disk.sh $(IMAGE) $(MOUNT)

image: root boot disk
	# Copy the output of debootstrap into the image
	cp -r $(DEBOOTSTRAP)/rootfs/* $(MOUNT)/
	cp -r $(DEBOOTSTRAP)/bootfs/* $(MOUNT)/boot/

unmount:
	# Unmount the image and remove temporary mount point
	umount $(MOUNT)/boot
	umount $(MOUNT)

	# Remove mount point
	rm -rf $(MOUNT)

dist:
	$(SCRIPT)/release.sh $(IMAGE) $(MAJOR_V).$(MINOR_V) .
