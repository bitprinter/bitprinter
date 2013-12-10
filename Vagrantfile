# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "vagrant-wheezy32"
  config.vm.box_url = "./src/vagrant/package.box"
  config.vm.provision "shell", path: "src/vagrant/provision.sh"

  # config.vm.provider :virtualbox do |vb|
    # Don't boot with headless mode
    # vb.gui = true
    # Use VBoxManage to customize the VM.
    # For example to change memory:
    # vb.customize ["modifyvm", :id, "--memory", "1024"]
  # end
end
