# What the code does

## Overview
This playbook performs **Step 1 - Domain Controller Setup** on the Windows server **dc01**:

- Installs the Active Directory Domain Services role (AD DS) and management tools
- Promotes the server to a Domain Controller
- Creates a new forest: **blueteamlab.local**
- Sets DNS to **10.10.10.20**
- Reboots the machine

The playbook is executed from the Ansible controller over WinRM.

## Variables (vars)
    vars:
      domain_name: blueteamlab.local
      domain_netbios: BLUETEAMLAB
      dc_dns_ip: "10.10.10.20"
      safe_mode_password: "passwd"

- **domain_name**: The domain FQDN (the name of the new forest).
- **domain_netbios**: The NetBIOS name
- **dc_dns_ip**: The DNS server IP. Here it is dc01’s own IP (10.10.10.20).
- **safe_mode_password**: The DSRM password for the Domain Controller.  

## DNS configuration (Configure DNS 10.10.10.20)
    - name: Set DNS client to the DC (10.10.10.20)
      ansible.windows.win_dns_client:
        adapter_names: '*'
        ipv4_addresses:
          - "{{ dc_dns_ip }}"

Sets the Windows DNS client to use **10.10.10.20** as the DNS server.

- `adapter_names: '*'` means it tries to apply the change to all adapters.
- `ipv4_addresses` sets the DNS list; here it contains only one address.

## AD DS role installation (Install Active Directory services)
    - name: Install Active Directory Domain Services
      ansible.windows.win_feature:
        name:
          - AD-Domain-Services
          - RSAT-AD-Tools
          - RSAT-DNS-Server
        state: present
        include_management_tools: true
      register: addds

Installs the AD DS role and the required management tools:

- **AD-Domain-Services**: the AD DS role itself
- **RSAT-AD-Tools**: AD management tools
- **RSAT-DNS-Server**: DNS management tools

`register: addds` stores the result so the playbook can check whether a reboot is required.

## Reboot after role installation (if needed)
    - name: Reboot if feature installation requires it
      ansible.windows.win_reboot:
        msg: "Rebooting after AD DS feature installation"
        reboot_timeout: 3600
      when: addds.reboot_required | default(false)

If Windows reports that the feature installation requires a reboot, the playbook reboots.

- The `when:` condition makes it idempotent: it reboots only when needed.
- `reboot_timeout: 3600` gives the VM enough time to come back even in slower environments.

## Domain Controller promotion + forest creation
    - name: Promote server to Domain Controller and create new forest
      ansible.windows.win_domain:
        dns_domain_name: "{{ domain_name }}"
        domain_netbios_name: "{{ domain_netbios }}"
        safe_mode_password: "{{ safe_mode_password }}"
      register: promo

Promotes the server to a Domain Controller and creates a new forest.

- `dns_domain_name`: the forest/domain name to create (**blueteamlab.local**)
- `domain_netbios_name`: the NetBIOS name (**BLUETEAMLAB**)
- `safe_mode_password`: the DSRM password

`register: promo` stores the promotion result (including whether a reboot is required).

## Reboot after promotion
    - name: Reboot after domain promotion
      ansible.windows.win_reboot:
        msg: "Rebooting after domain controller promotion"
        reboot_timeout: 3600
      when: promo.reboot_required | default(true)

Domain Controller promotion almost always requires a reboot.

- `default(true)` makes reboot the default so the step isn’t skipped if the module doesn’t return the expected value.

## Waiting for WinRM to return
    - name: Wait for WinRM to return after reboot
      ansible.windows.win_wait_for:
        port: 5985
        delay: 10
        timeout: 600

After reboot, Ansible waits until WinRM (HTTP) is available again on port **5985**.

- `delay: 10` waits briefly before checking
- `timeout: 600` allows up to 10 minutes for WinRM to come back

## Summary
This playbook automates the basic Domain Controller setup:

- Ensures DNS is set correctly (dc01 → 10.10.10.20)
- Installs the AD DS role and tools
- Creates a new forest (**blueteamlab.local**) and promotes dc01 to DC
- Handles required reboots
- Waits for WinRM to return so the next playbook steps can run
