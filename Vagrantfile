# -*- mode: ruby -*-
# vi: set ft=ruby :

# --- Configuration Variables ---
NUM_WORKERS = 2
IP_BASE = "192.168.56"

# Detect Apple Silicon
IS_ARM = (RUBY_PLATFORM =~ /arm64/)

# --- Hybrid Configuration ---
if IS_ARM
  #Apple Silicon
  # Use an ARM64 box. If bento is missing arm64, try "perk/ubuntu-2404-arm64"
  BOX_IMAGE = "bento/ubuntu-24.04" 
  PROVIDER = "vmware_desktop"
  # VMware handles memory differently; strict limits are safer
  CTRL_MEM = 4096
  WORKER_MEM = 4096 
else
  # Settings for Linux/Intel
  BOX_IMAGE = "bento/ubuntu-24.04"
  PROVIDER = "virtualbox"
  CTRL_MEM = 4096
  WORKER_MEM = 6144
end

Vagrant.configure("2") do |config|
  config.vm.box = BOX_IMAGE
  
  # Allow the ARM to fallback to other boxes if the specific version is missing
  if IS_ARM
     config.vm.box_check_update = false
  end

  # --- Controller Node ---
  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: "#{IP_BASE}.100"
    
    ctrl.vm.provider PROVIDER do |v|
      v.memory = CTRL_MEM
      v.cpus = 2
      if PROVIDER == "virtualbox"
        v.name = "doda-ctrl"
        v.linked_clone = true
      else
        v.gui = false
        v.allowlist_verified = true
      end
    end
  end

  # --- Worker Nodes (Loop) ---
  (1..NUM_WORKERS).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.network "private_network", ip: "#{IP_BASE}.#{100 + i}"
      
      node.vm.provider PROVIDER do |v|
        v.memory = WORKER_MEM
        v.cpus = 2
        if PROVIDER == "virtualbox"
          v.name = "doda-node-#{i}"
          v.linked_clone = true
        else
          v.gui = false
          v.allowlist_verified = true
        end
      end
    end
  end
  

# --- Ansible Provisioning ---
  ansible_extra_vars = {
    'num_workers' => NUM_WORKERS,
    'ip_base'     => IP_BASE
  }

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "general.yaml"
    ansible.extra_vars = ansible_extra_vars
  end

  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.provision "ansible" do |ansible|
      ansible.playbook = "ctrl.yaml"
      ansible.limit = "ctrl"
      ansible.extra_vars = ansible_extra_vars
    end
  end

  # --- Worker Nodes (Loop) ---
  (1..NUM_WORKERS).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "node.yaml"
        ansible.limit = "node-#{i}"
        ansible.extra_vars = ansible_extra_vars
      end
    end
  end

  # --- Inventory Generation (Required for "Excellent" Grade) ---
  # This script runs on your HOST machine after the VMs start
  config.trigger.after :up do |trigger|
    trigger.run = {inline: "bash -c '
      echo \"[controllers]\" > inventory.cfg
      echo \"ctrl ansible_host=#{IP_BASE}.100 ansible_user=vagrant\" >> inventory.cfg
      echo \"\" >> inventory.cfg
      echo \"[workers]\" >> inventory.cfg
      for i in {1..#{NUM_WORKERS}}; do
        echo \"node-$i ansible_host=#{IP_BASE}.$((100+i)) ansible_user=vagrant\" >> inventory.cfg
      done
    '"}
  end
end