# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  name = "commit-email.info"
  config.vm.define(name) do |node|
    node.vm.box = "debian-8-x86_64"
    node.vm.box_url = "http://packages.groonga.org/tmp/opscode_debian-8.0_chef-provisionerless.box"
    node.vm.network "public_network"
    node.vm.provision :ansible do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.groups = {
        "servers" => [name],
      }
      ansible.host_key_checking = false
    end
  end
end
