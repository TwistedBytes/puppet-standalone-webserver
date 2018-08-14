# -*- mode: ruby -*-
# vi: set ft=ruby :

# -- config section
node_domain  = 'tbdev.xyz'
node_name    = 'puppetstandalone'.concat('.' + node_domain)
node_aliases = ['twistedbytes-site1', 'twistedbytes-site2'].map{|s| s.concat('.' + node_domain)}
# node_aliases = [].map{|s| s.concat('.' + node_domain)}
node_ip      = "192.168.50.120"
node_cpus    = 2
node_memory  = 2048
# -- end config section

Vagrant.configure(2) do |config|
  # -- hostmanager section
  # vagrant plugin install vagrant-hostmanager
  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = false
  end
  # -- end hostmanager section

  config.vm.define node_name do |node|
    # -- box setup
    node.vm.box = "twistedbytes/centos-7"
    node.vm.hostname = node_name
    node.vm.provider "virtualbox" do |v|
      v.linked_clone = true if Gem::Version.new(::Vagrant::VERSION) > Gem::Version.new('1.8')
      v.name   = node_name
      v.memory = node_memory
      v.cpus   = node_cpus
    end

    if Vagrant.has_plugin?("vagrant-hostmanager")
      if !node_aliases.empty?
        node.hostmanager.aliases = node_aliases
      end
    end

    # -- box setup

    # -- network section
    node.vm.network "private_network", ip: node_ip

    # -- synced folders section
    node.vm.synced_folder "puppet",            "/data/puppet",   create: true
    # -- end synced folders section

    # -- provisioning section
    # node.vm.provision "shell", run: 'always', inline: '/usr/local/bin/autorun.sh'
    node.vm.provision "shell", inline: 'time /data/puppet/scripts/initial.sh'

    # -- provisioning section

  end
end
