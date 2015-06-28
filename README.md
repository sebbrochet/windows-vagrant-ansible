windows-vagrant-ansible
=======================

Windows is not currently supported by [Ansible][1] which means the standard Ansible plugin provided with
[Vagrant][2] cannot be used with this platform. The provision.sh script takes advantage of Vagrant's
[shell provisioning][3] facilities to allow the use of Ansible from within a VM regardless of the host platform.

Debian and CentOS systems are currently supported.

Usage
-----

Place `shell` directory wherever you like. You should then configure Vagrant to use
shell provisioning where sh.path refers to provision.sh. Three options are required and must be
supplied using sh.args in the following order:

1. The OS the target VM is running on (i.e "debian" or "centos")
2. The Ansible playbook to run
3. The Ansible hosts inventory file to use

An example Vagrantfile is below:

```ruby
Vagrant.configure("2") do |config|

  # ...

  config.vm.provision :shell do |sh|
    sh.path = "../../../shell/provision.sh"
    sh.args = "debian setup.yml vagrant.hosts"
  end
end
```

Have a look on projects under `demos` directory for full examples.

[1]: http://www.ansibleworks.com "Ansible"
[2]: http://www.vagrantup.com/ "Vagrant"
[3]: http://docs.vagrantup.com/v2/provisioning/shell.html "Shell Provisioning"
