installation
============

These instructions are tested on *NIX-like environments (OS X & popular linux
distros). If you encounter any difficulties during the installation please let
me know. This guide will walk you through the first-time setup, building images,
as well as provide some direction on how to modify and test bitprinter.


you will need
-------------

* At least 10 GB of disk space (5 might work)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Packer](http://www.packer.io/downloads.html)
* [Vagrant](http://www.vagrantup.com/downloads.html)
* [git](http://git-scm.com/downloads)
* (optional) QEMU


the easy way
------------
Start by cloning this repository

    git clone https://github.com/bitprinter/bitprinter.git bitprinter

Then launch the build environment and make an image. Running this can take up to
several hours and result in approximately 3 GB in downloads.

    cd bitprinter
    make lib
    make build

If you have QEMU installed on your host machine, you can test the latest image:

    make emulator

Now you have a full and functional bitprinter image. Burn this to an SD card as
you would any other image for Raspberry Pi.


the hard way
------------

If you've come this far, then chances are you want to customize the OS that is
produced so you can make your Raspberry Pi do something new. All customization
should be put into rpi/script/config.sh. This gets run after the second-stage
bootstrap and while we are still able to chroot into an emulated environment.
This is where we set a root password, set our hostname, apply other
configuration, install needed packages and remove those that are not needed.
Instructions for more manual setup will be ready soon.


benchmarks
==========

Dec 10 2013
-----------

git clone https://github.com/bitprinter/firmware.git lib/firmware   : 20m 38s

vagrant up                                                          : 59m 22s

vagrant ssh -c "cd /vagrant ; sudo make"                            : 7m 45s

total                                                               : 87m 45s
