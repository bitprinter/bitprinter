#!/bin/bash -e

# Strip down Debian (wheezy) and prepare for Vagrant.
#
# Copy this to a clean Debian VM and run as root before creating a Vagrant box.

# Remove unneeded packages
apt-get -y purge \
aptitude \
aptitude-common \
at \
bash-completion \
bind9-host \
ca-certificates \
console-setup \
console-setup-linux \
dc \
debian-faq \
dictionaries-common \
doc-debian \
eject \
file \
ftp \
geoip-database \
groff-base \
iamerican \
ibritish \
ienglish-common \
info \
installation-report \
ispell \
laptop-detect \
man-db \
manpages \
manpages-dev \
mutt \
ncurses-term \
net-tools \
netcat-traditional \
openssh-blacklist \
openssh-blacklist-extra \
procmail \
reportbug \
task-english \
tasksel \
tasksel-data \
telnet \
traceroute \
util-linux-locales \
vim-common \
w3m \
wamerican \
whois

# Remove orphaned deps
apt-get -y autoremove

# Install vagrant specific deps
apt-get -y install build-essential module-assistant
m-a prepare
apt-get -y install openssh-server zerofree sudo

# Install bitprinter build dependencies
apt-get -y install qemu qemu-user qemu-user-static binfmt-support
apt-get -y install dosfstools e2fsprogs kpartx debootstrap

# Set up SSH with default insecure vagrant key
mkdir -p /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
mv vagrant.pub authorized_keys
cd -
chmod 700 /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh

# Add user 'vagrant' to sudoers
echo "vagrant   ALL = NOPASSWD: ALL" >> /etc/sudoers

# Remove locale info, manpages
mv /usr/share/locale/en ~/tmp_locale
rm -rf /usr/share/locale/*
mv ~/tmp_locale /usr/share/locale/en
rm -rf /usr/share/man/*

# Remove apt package cache
apt-get -y clean

# Remove cache and tmp files
find /var/cache -type f -exec rm -rf {} \;
rm -rf /tmp/*

# Now run zerofree
echo "Killing unneeded processes ..."
service rsyslog stop
service network-manager stop
killall dhclient

echo "Remounting read-only ..."
mount -o remount,ro /dev/sda1

echo "Writing zeros to free space to improve compression ..."
zerofree /dev/sda1
