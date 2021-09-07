#!/bin/bash

ROOT=$1
INVENTORIES=inventories
ENVS=(production staging development)
ENV_PRD=production
ENV_STG=staging
ENV_DEV=development
GROUP_VARS=group_vars
HOST_VARS=host_vars
A_GROUPS=(web db)

function create_hosts_yml {
  echo -n "create inventory $2 hosts.yml ..."
  path=$1/hosts.yml

  cat <<EOT > $path
---
# $env hosts

all:
  vars:
    ansible_user: vagrant
    ansible_port: 22
  hosts:
EOT

  for group in ${A_GROUPS[@]}
  do
    cat <<EOT >> $path
$group:
  vars:
  hosts:
    ${group}01:
      ansible_host: 192.168.33.10
EOT

  echo "done."
  done
}

function create_inventories {
  envs=($ENV_PRD $ENV_STG $ENV_DEV)
  for env in ${envs[@]}
  do
    dir=$ROOT/$INVENTORIES/$env
    echo -n "create inventory $env ..."

    # create group_vars and host_vars
    for group in ${A_GROUPS[@]}
    do
      mkdir -p $dir/$GROUP_VARS
      cat <<EOT > $dir/$GROUP_VARS/${group}.yml

---
# group vars for group "${group}"
EOT

      # create host vars dir
      mkdir -p $dir/$HOST_VARS
      cat <<EOT > $dir/$HOST_VARS/${group}01.yml
---
# host vars for host "${group}01"
EOT

      # create group vars for "all"
      cat <<EOT > $dir/$GROUP_VARS/all.yml

---
# group vars for all groups
EOT

      # create host vars for "all"
      cat <<EOT > $dir/$HOST_VARS/all.yml
---
# group vars for all groups
EOT
    done
    echo "done."

    create_hosts_yml $dir $env
  done
}

function create_playbook_yml {
  for group in ${A_GROUPS[@]}
  do
    echo -n "create playbook for $group ..."
    cat <<EOT > $ROOT/$group.yml
---
- hosts: $group
  become: yes
  become_user: root
  roles:
    #- { role: the_role, tags: the_role }
EOT
    echo "done."
  done
}

function create_site_yml {
  echo -n "create site.yml ..."
  path=$ROOT/site.yml
  cat <<EOT > $path
---
- import_playbook: common.yml
EOT

  for group in ${A_GROUPS[@]}
  do
    cat <<EOT >> $path
- import_playbook: $group.yml
EOT
  done
  echo "done."
}

function create_common_yml {
  echo -n "create common.yml ..."
  path=$ROOT/common.yml
  cat <<EOT > $path
---
- hosts: all
  become: yes
  become_user: root
  roles:
    - server_info
EOT
  echo "done."
}

function create_ansible_cfg {
  echo -n "create ansible.cfg ..."
  path=$ROOT/ansible.cfg
  cat <<EOT > $path
[defaults]
roles_path = ./roles
retry_files_enabled = false

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

[galaxy]
ignore_certs = true
EOT
  echo "done."
}

function create_server_info_role {
  dir=$ROOT/roles/server_info
  echo -n "create $dir ..."
  tasks_dir=$dir/tasks

  mkdir -p $tasks_dir

  cat <<EOT > $tasks_dir/main.yml
---
- name: display host ips
  debug:
    var: ansible_all_ipv4_addresses
  changed_when: false
  check_mode: no

- name: get remote user info
  shell: "id"
  register: result
  changed_when: false
  check_mode: false

- name: display remote user info
  debug:
    var: result
EOT
  echo "done."
}

function create_dot_gitignore {
  echo -n "create .gitignore ..."
  cat <<EOT > $ROOT/.gitignore
*.retry
.vagrant
EOT
  echo "done."
}

function create_vagrantfile {
  echo -n "create Vagrantfile ..."
  cat <<EOT > $ROOT/Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7"
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end
end
EOT
  echo "done."
}

if [ -z "$1" ];then
  echo "invalid arguments."
  exit 1
fi


mkdir -p $ROOT/roles
create_inventories
create_playbook_yml
create_site_yml
create_common_yml
create_ansible_cfg
create_server_info_role
create_dot_gitignore
create_vagrantfile
git -C $ROOT init

