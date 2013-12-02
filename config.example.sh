# Example configuration file - Copy this to config.sh and make any desired changes there.

# Set root password
echo "root:bitprinter" | chpasswd

# Set hostname
echo "bitprinter" > /etc/hostname

# Create default user
useradd -m -G sudo -s /bin/bash bitprinter
echo "bitprinter:bitprinter" | chpasswd

