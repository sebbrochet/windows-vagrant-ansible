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

# Configure some parameters here:

$parameters = {
  "project"   => "vagrant-vm",
  "memory"    => 2048,
  "cpus"      => 1,
  "provision_shell" => "../../../provision.sh",  
  "vagrant_box" => "hansode/centos-6.6-x86_64",
  "ansible_host_file" => "vagrant.hosts",
  "ansible_playbook" => "site.yml",
  "roles_dir" => "../../roles", # optional: remove key if you do not use an external `roles` directory
  "vault_password_file" => "vault_pass.txt" # optional: remove key if you do not use vault-protected files
}

work_dir=".ansible"
require 'fileutils'
FileUtils.rmtree work_dir

if $parameters.has_key?("roles_dir")
  FileUtils::mkdir_p work_dir
  FileUtils.copy_entry $parameters['roles_dir'], work_dir
end

Vagrant.configure(2) do |config|
  config.vm.box = $parameters['vagrant_box']
  config.vm.synced_folder ".", "/vagrant"

  config.vm.hostname = $parameters['project']
  
  config.vm.provision :shell do |sh|
    sh.path = $parameters['provision_shell']

    if $parameters.has_key?("vault_password_file")
       sh.args = $parameters['ansible_playbook'] + " " + $parameters['ansible_host_file'] + " " + $parameters['vault_password_file']
    else
       sh.args = $parameters['ansible_playbook'] + " " + $parameters['ansible_host_file']
    end
  end
end
```

Have a look on projects under `demos` directory for full examples.

[1]: http://www.ansibleworks.com "Ansible"
[2]: http://www.vagrantup.com/ "Vagrant"
[3]: http://docs.vagrantup.com/v2/provisioning/shell.html "Shell Provisioning"
