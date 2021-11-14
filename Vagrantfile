# -*- mode: ruby -*-
# vi: set ft=ruby ai et sw=2 :
ENV['VAGRANT_EXPERIMENTAL'] = 'typed_triggers'

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.vm.provider :libvirt do |libvirt|
    libvirt.qemu_use_session = false
    libvirt.memory = 1024
    libvirt.cpus = 1
  end

  config.vm.network 'forwarded_port',
    guest: 80,
    guest_ip: '192.168.10.254',
    host: 8080

  (1..2).each do |i|
    config.vm.define "fw#{i}" do |fw|
      fw.vm.network :private_network,
        ip: "192.168.10.#{1 + i}"
      fw.vm.network :private_network,
        ip: "192.168.11.#{1 + i}",
        libvirt__forward_mode: "none"
      fw.vm.hostname = "fw#{i}"
      # fw.vm.provision :shell,
      #   path: 'fw-common.sh',
      #   args: ["100", "lh62V.bF"]
    end
  end

  (1..2).each do |i|
    config.vm.define "client#{i}" do |client|
      client.vm.network :private_network,
        ip: "192.168.11.#{250 + i}",
        libvirt__forward_mode: "none"
      client.vm.hostname = "client#{i}"
    end
  end

  config.trigger.before [:up, :provision, :reload], type: :command do |trigger|
    trigger.info = 'Initializing bolt'
    trigger.run = { inline: 'bolt module install' }
  end

  config.trigger.after [:up, :provision, :reload], type: :command do |trigger|
    trigger.info = 'Running bolt plan'
    trigger.run = { inline: 'bolt plan run ha_firewall --run-as root --verbose', }
  end
end
