#!/bin/bash

set -e
#set -x

ANSIBLE_OS=$1
ANSIBLE_PLAYBOOK=$2
ANSIBLE_HOSTS=$3
ANSIBLE_DIR="./ansible"
TEMP_HOSTS="/tmp/ansible_hosts"
ANSIBLE_VERSION="v1.9.2-1"

install_ansible_debian_IFN()
{
    if [ ! -d $ANSIBLE_DIR ]; then
        cwd=`pwd`
        
        echo "Updating apt cache"
        apt-get update
        
        echo "Installing Ansible dependencies and Git"
        apt-get install -y git python-yaml python-paramiko python-jinja2 python-pip
        
        echo "Installing others dependencies with pip"
        pip install six
        
        echo "Cloning Ansible"	
        git clone git://github.com/ansible/ansible.git --recursive ${ANSIBLE_DIR}
        
        echo "Selecting stable version (${ANSIBLE_VERSION})"
        cd ${ANSIBLE_DIR}
        git checkout tags/${ANSIBLE_VERSION}	
        
        cd $cwd
    fi
}

install_ansible_centos_IFN()
{
    if [ ! -d $ANSIBLE_DIR ]; then
        cwd=`pwd`
        
        echo "Adding EPEL repo for python-pip"
        rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
        
        echo "Installing Ansible dependencies and Git"
        yum install -y python-yaml python-paramiko python-jinja2 python-pip git	
        
        echo "Installing others dependencies with pip"
        pip install six
        
        echo "Cloning Ansible"	
        git clone git://github.com/ansible/ansible.git --recursive ${ANSIBLE_DIR}
        
        echo "Selecting stable version (${ANSIBLE_VERSION})"
        cd ${ANSIBLE_DIR}
        git checkout tags/${ANSIBLE_VERSION}	
        
        cd $cwd
    fi
}

if [ ! -f /vagrant/$ANSIBLE_PLAYBOOK ]; then
        echo "Cannot find Ansible playbook: /vagrant/${ANSIBLE_PLAYBOOK}"
        exit 1
fi

if [ ! -f /vagrant/$ANSIBLE_HOSTS ]; then
        echo "Cannot find Ansible hosts: /vagrant/${ANSIBLE_HOSTS}"
        exit 2
fi

if [ ${ANSIBLE_OS} == "debian" ]; then
   echo "Configuring Ansible on Debian..."
   install_ansible_debian_IFN
elif [ ${ANSIBLE_OS} == "centos" ]; then
   install_ansible_centos_IFN
else
   echo "${ANSIBLE_OS} is not (yet) supported, sorry."
   exit 1
fi

cd ${ANSIBLE_DIR}
cp /vagrant/${ANSIBLE_HOSTS} ${TEMP_HOSTS} && chmod -x ${TEMP_HOSTS}
echo "Running Ansible"
bash -c "source hacking/env-setup && ansible-playbook /vagrant/${ANSIBLE_PLAYBOOK} --inventory-file=${TEMP_HOSTS} --connection=local"
rm ${TEMP_HOSTS}