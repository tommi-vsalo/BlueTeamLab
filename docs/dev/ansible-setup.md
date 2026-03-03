# WSL2 Ansible Controller → VirtualBox Ubuntu VM (SSH + Playbook Run)

## What I set up (final architecture)
- **Windows host** running **WSL2 Ubuntu** named **`btlab`** (this is my **Ansible controller**).
- **VirtualBox Ubuntu VM** named **`machine`** (this is my **Ansible target**).
- VirtualBox networking is **Bridged**, so the VM behaves like a real computer on your LAN and gets its own IP.
- **SSH from `btlab` → `machine` works**.

---

## What I did

### 1) Created/used a VirtualBox VM as a “whole computer”
- I created an Ubuntu VM in VirtualBox (a full separate OS instance).
- I set **Adapter 1 = Bridged** so the VM gets a LAN IP and is reachable from my WSL controller.

### 2) Enabled SSH on the VM (`machine`)
On the VM I installed/started SSH so it can accept remote connections:
- `openssh-server` installed
- SSH service running on port **22**

### 3) Verified SSH connectivity from WSL (`btlab`) to the VM
From WSL I confirmed I can connect:
- `ssh machine@192.168.50.5` (works)

### 4) Created an Ansible inventory on WSL
I created:
- Directory: `inventory/`
- File: `inventory/hosts.ini`

With this content:
```ini
[lab1]
machine ansible_host=192.168.50.5 ansible_user=machine
```

### 5) Wrote and ran an Ansible playbook from WSL against the VM
My playbook targets the inventory group **`lab1`** and uses `become: true`:
- Updates APT cache
- Installs package(s) (example: `curl`)

Run command (from WSL):
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

If sudo password prompting was needed:
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --become -K
```

---

## Key commands you can reuse

### Test host reachability via Ansible
```bash
ansible -i inventory/hosts.ini lab1 -m ping
```

### Run playbook
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

### Target only one host (optional)
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml -l machine
```

---

## Difficulties I hit and how they were solved

### 1) “WSL doesn’t have an IP”
**Problem:** My WSL2 instance doesn’t show a normal LAN IP like a physical machine because it runs behind a virtual NAT.  
**Solution:** I didn’t need a LAN IP on WSL to control the VM. The controller initiates outbound connections, so as long as:
- WSL can reach the VM’s LAN IP, and
- SSH works to the VM,  
Ansible works.

### 2) Understanding where the playbook runs
**Problem:** At first it felt like the playbook should “run on the VM.”  
**Solution:** In Ansible, the **playbook runs on the controller** (`btlab`), and it executes tasks on the target (`machine`) over SSH.

### 3) Matching `hosts:` in the playbook to the inventory
**Problem:** If `hosts: lab1` doesn’t match my inventory group name, Ansible won’t target anything.  
**Solution:** My inventory group is `[lab1]`, so `hosts: lab1` is correct.

### 4) SSH connectivity vs. VirtualBox networking modes
**Problem:** NAT networking often requires port forwarding and can block direct SSH to the VM from other systems.  
**Solution:** I used **Bridged networking**, so the VM gets a real LAN IP (`192.168.50.5`) and SSH works directly.

---

## Current state (confirmed working)
- Controller: **WSL2 Ubuntu `btlab`**
- Target: **VirtualBox VM `machine`**
- Inventory: **`inventory/hosts.ini`** with group **`lab1`**
- VM IP: **`192.168.50.5`**
- SSH works
- Ansible playbooks run successfully from WSL to the VM
