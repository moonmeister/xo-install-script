# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  # Generic config

  config.vm.synced_folder ".", "/xoctl"

  config.vm.network "forwarded_port", guest: 80, host: 8080
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end

  ## define ubuntu vm
  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "ubuntu/xenial64"
  end

  ## define debian vm (autostart: false makes sure if you run `vagrant up` with no paramaters both boxes don't start)
  config.vm.define "debian", autostart: false do |debian|
    debian.vm.box = "debian/jessie64"
  end

end
