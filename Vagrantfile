# -*- mode: ruby -*-
# vi: set ft=ruby ai et sw=2 :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  #config.vm.provider :libvirt do |libvirt|
  #  libvirt.storage_pool_name = "sas15k_vmimages"
  #end

  config.vm.define "fw1" do |fw1|
    fw1.vm.network :private_network,
      :ip => "192.168.10.2"
    fw1.vm.network :private_network,
      :ip => "192.168.11.2",
      :libvirt__forward_mode => "none"
    fw1.vm.hostname = "fw1"
    fw1.vm.provider :libvirt do |libvirt|
      libvirt.memory = 1024
      libvirt.cpus = 1
    end
    fw1.vm.provision :shell,
      :path => 'fw-common.sh',
      :args => ["100", "lh62V.bF"]
  end

  config.vm.define "fw2" do |fw2|
    fw2.vm.network :private_network,
      :ip => "192.168.10.3"
    fw2.vm.network :private_network,
      :ip => "192.168.11.3",
      :libvirt__forward_mode => "none"
    fw2.vm.hostname = "fw2"
    fw2.vm.provider :libvirt do |libvirt|
      libvirt.memory = 1024
      libvirt.cpus = 1
    end
    fw2.vm.provision :shell,
      :path => 'fw-common.sh',
      :args => ["100", "lh62V.bF"]
  end

  config.vm.define "client" do |client|
    client.vm.network :private_network,
      :ip => "192.168.11.253",
      :libvirt__forward_mode => "none"
    client.vm.hostname = "client"
    client.vm.provider :libvirt do |libvirt|
      libvirt.memory = 1024
      libvirt.cpus = 1
    end
    client.vm.provision :shell,
      :path => 'client.sh'
  end
end
