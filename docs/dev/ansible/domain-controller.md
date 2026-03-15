# What i have
- **Ansible-controller 10.10.10.10**
- **Windows Server 10.10.10.20**

Ansible and WinRm setup (see previous guide for setup)

## What i want to do

Perform **Domain Controller Setup** on the Windows server **dc01**:

- Install the Active Directory Domain Services role (AD DS) and management tools
- Promotes the server to a Domain Controller
- Creates a new forest: **blueteamlab.local**
- Sets DNS to **10.10.10.20**
- Reboots the machine

The playbook will be executed from the Ansible controller over WinRM.

---

# The playbook
the playbook is created inside the **playbooks** folder under the name `domain_controller_promotion.yml`

The code is following:

```bash
- name: Domain Controller Setup
  hosts: dc01
  gather_facts: false
  become: true
  become_method: runas
  become_user: pihla

  vars:
    domain_name: blueteamlab.local
    domain_netbios: BLUETEAMLAB
    dc_dns_ip: "10.10.10.20"
    safe_mode_password: "l48r4"

  tasks:
    - name: Set DNS client to the DC
      ansible.windows.win_dns_client:
        adapter_names:
          - "Ethernet 2"
        ipv4_addresses:
          - "{{ dc_dns_ip }}"

    - name: Install Active Directory Domain Services
      ansible.windows.win_feature:
        name:
          - AD-Domain-Services
          - RSAT-AD-Tools
          - RSAT-DNS-Server
        state: present
        include_management_tools: true
      register: ad_ds_install

    - name: Reboot if feature installation requires it
      ansible.windows.win_reboot:
        msg: "Rebooting after AD DS installation"
        reboot_timeout: 3600
      when: ad_ds_install.reboot_required | default(false)

    - name: Promote server and create forest
      ansible.windows.win_domain:
        dns_domain_name: "{{ domain_name }}"
        domain_netbios_name: "{{ domain_netbios }}"
        safe_mode_password: "{{ safe_mode_password }}"
      register: promotion

    - name: Reboot after promotion
      ansible.windows.win_reboot:
        msg: "Rebooting"
        reboot_timeout: 3600
      when: promotion.reboot_required | default(true)

    - name: Wait for reboot
      ansible.windows.win_wait_for:
        port: 5985
        delay: 10
        timeout: 600
```

---

# What the code does
## Header
    - name: Domain Controller Setup
      hosts: dc01
      gather_facts: false
      become: true
      become_method: runas
      become_user: pihla

## Variables (vars)
    vars:
      domain_name: blueteamlab.local
      domain_netbios: BLUETEAMLAB
      dc_dns_ip: "10.10.10.20"
      safe_mode_password: "l48r4"

- **domain_name**: The domain name for the new forest.
- **domain_netbios**: The NetBIOS name
- **dc_dns_ip**: The DNS server IP. Here it is dc01’s own IP (10.10.10.20).
- **safe_mode_password**: The password for the Domain Controller.  

## DNS configuration (Configure DNS 10.10.10.20)
    - name: Set DNS client to the DC (10.10.10.20)
      ansible.windows.win_dns_client:
        adapter_names:
          - "Ethernet 2"
        ipv4_addresses:
          - "{{ dc_dns_ip }}"

Sets the Windows DNS client to use **10.10.10.20** as the DNS server.

- `adapter_names:` means it tries to apply the change to only Ethernet 2 10.10.10.20.
- `ipv4_addresses` here it contains only one address, 10.10.10.20.

## AD DS role installation
    - name: Install Active Directory Domain Services
      ansible.windows.win_feature:
        name:
          - AD-Domain-Services
          - RSAT-AD-Tools
          - RSAT-DNS-Server
        state: present
        include_management_tools: true
      register: ad_ds_install

Installs the AD DS role and the required management tools:

- **AD-Domain-Services**: the AD DS role itself
- **RSAT-AD-Tools**: AD management tools
- **RSAT-DNS-Server**: DNS management tools

`register: ad_ds_install` stores the result so the playbook can check whether a reboot is required.

## Reboot after role installation (if needed)
    - name: Reboot if feature installation requires it
      ansible.windows.win_reboot:
        msg: "Rebooting after AD DS feature installation"
        reboot_timeout: 3600
      when: ad_ds_install.reboot_required | default(false)

If Windows reports that the feature installation requires a reboot, the playbook reboots.

- The `when:` condition makes it idempotent: it reboots only when needed.
- `reboot_timeout: 3600` gives the VM enough time to come back even in this slow environment.

## Domain Controller promotion + forest creation
    - name: Promote server to Domain Controller and create new forest
      ansible.windows.win_domain:
        dns_domain_name: "{{ domain_name }}"
        domain_netbios_name: "{{ domain_netbios }}"
        safe_mode_password: "{{ safe_mode_password }}"
      register: promotion

Promotes the server to a Domain Controller and creates a new forest.

- `dns_domain_name`: the forest/domain name to create (**blueteamlab.local**)
- `domain_netbios_name`: the NetBIOS name (**BLUETEAMLAB**)
- `safe_mode_password`: the DSRM password

`register: promotion` stores the promotion result (including whether a reboot is required).

## Reboot after promotion
    - name: Reboot after domain promotion
      ansible.windows.win_reboot:
        msg: "Rebooting after domain controller promotion"
        reboot_timeout: 3600
      when: promotion.reboot_required | default(true)

Domain Controller promotion almost always requires a reboot.

- `default(true)` makes reboot the default so the step isn’t skipped if the module doesn’t return the expected value.

## Waiting for WinRM to return
    - name: Wait for reboot
      ansible.windows.win_wait_for:
        port: 5985
        delay: 10
        timeout: 600

After reboot, Ansible waits until WinRM (HTTP) is available again on port **5985**.

- `delay: 10` waits briefly before checking
- `timeout: 600` allows up to 10 minutes for WinRM to come back

---

# Running the playbook

Now for running the playbook we use command `ansible-playbook -i inventory/hosts.ini playbooks/domain_controller_promotion.yml`. The code line `hosts: dc01` makes it so it only runs on dc01 and not other computers.

# Problem

This is where i ran in to a big problem that makes it impossible for me to run the playbook and/or make the Server a domain controller. The problem is that it is not a Server but a normal Windows 10 Pro. and a Windows 10 Pro can not install or become a domain controller

So this is as far as i can get right now..

