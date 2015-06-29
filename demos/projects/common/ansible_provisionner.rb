# Common part for all demo projects

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