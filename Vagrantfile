# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2110"
  config.vm.provider "virtualbox"
  config.vm.network "private_network", type: "dhcp"
  config.vm.provision "shell", path: 'scripts/setup.sh'
end
