# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "vagrant-wheezy32"
  config.vm.box_url = "./lib/package.box"
  config.vm.provision "shell", path: "rpi/provision.sh"
end
