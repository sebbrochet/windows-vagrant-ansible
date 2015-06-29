#!/bin/bash

set -e
set -u
#set -x

ANSIBLE_PLAYBOOK=$1
ANSIBLE_HOSTS=$2
VAULT_PASSWORD_FILE=${3:-""}
ANSIBLE_DIR="./ansible"
TEMP_HOSTS="/tmp/ansible_hosts"
TEMP_VAULT_FILE="/tmp/vault_pass.txt"
ANSIBLE_VERSION="v1.9.2-1"

install_ansible_debian_IFN()
{
    if [ ! -d $ANSIBLE_DIR ]; then
        cwd=`pwd`

        echo "Updating apt cache"
        apt-get update

        echo "Installing Ansible dependencies and Git"
        apt-get install -y git python-yaml python-paramiko python-jinja2 python-pip dos2unix

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
        yum install -y python-yaml python-paramiko python-jinja2 python-pip git dos2unix

        echo "Installing others dependencies with pip"
        pip install six

        echo "Upgrading pycrypto (required by Vault)"
        yum install -y python-devel && rpm -e --nodeps python-crypto && pip install pycrypto

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

if [ -f /etc/debian_version ]; then
    echo "Configuring Ansible on Debian-like OS..."
    install_ansible_debian_IFN
elif [ -f /etc/redhat-release ]; then    
    echo "Configuring Ansible on Redhat-like OS..."
    install_ansible_centos_IFN
else
    echo "Only Debian and Redhat like OS are supported, sorry."
    exit 1
fi

if [ -d "/vagrant/.ansible" ]; then
    echo "Updating copy of roles before running playbooks..."
    rm -rf /etc/ansible/roles
    mkdir -p /etc/ansible/roles
    cp -rp /vagrant/.ansible/* /etc/ansible/roles
        
    if [ ! -z "$VAULT_PASSWORD_FILE" ]; then
        echo "convert files to unix format (required for Vault to decode correctly)"
        find /etc/ansible/roles -type f -print0 | xargs -0 dos2unix
    fi
else
    rm -rf /etc/ansible/roles
fi

cd ${ANSIBLE_DIR}
cp /vagrant/${ANSIBLE_HOSTS} ${TEMP_HOSTS} && chmod -x ${TEMP_HOSTS}

echo "Running Ansible"
if [ ! -z "$VAULT_PASSWORD_FILE" ]; then
    if [ ! -f /vagrant/${VAULT_PASSWORD_FILE} ]; then
        echo "Vault password file not found: /vagrant/${VAULT_PASSWORD_FILE}"
        exit 1
    fi
    
    cp /vagrant/${VAULT_PASSWORD_FILE} ${TEMP_VAULT_FILE} && chmod -x ${TEMP_VAULT_FILE}
    bash -c "source hacking/env-setup && ansible-playbook /vagrant/${ANSIBLE_PLAYBOOK} --vault-password-file ${TEMP_VAULT_FILE} --inventory-file=${TEMP_HOSTS} --connection=local"
    rm ${TEMP_VAULT_FILE}
else
    bash -c "source hacking/env-setup && ansible-playbook /vagrant/${ANSIBLE_PLAYBOOK} --inventory-file=${TEMP_HOSTS} --connection=local"
fi

rm ${TEMP_HOSTS}

if [ -d "/vagrant/.ansible" ]; then
    rm -rf /vagrant/.ansible
fi