# OpenTofu Scripting - Proof of Concept

## Purpose
The purpose of this proof of concept was to evaluate whether some image configuration tasks could be replaced with a script-based installation to better support the infrastructure-as-code approach.

## Testing Scope
The following script tests were performed:

- **Windows Server**: Configuring Firewall and WinRM using PowerShell
- **Ansible Controller**: Running basic startup scripts

## Windows Server Test
PowerShell commands were tested to ensure that the required connection settings
can be configured via script.

The following tasks were validated:
- ICMP (ping) enabled in Windows Firewall.
- WinRM Basic Authentication and AllowUnencrypted enabled for test use.

<img width="565" height="245" alt="image" src="https://github.com/user-attachments/assets/39ba3429-dc2e-4d92-aade-f602591ca595" />

<img width="890" height="581" alt="image" src="https://github.com/user-attachments/assets/d2d9fbc6-1047-4d20-bc84-886eae41b09b" />


## Ansible Controller Test
A simple Bash startup script was run to verify that services
and basic system configuration can be handled by a script.

<img width="548" height="183" alt="image" src="https://github.com/user-attachments/assets/cb58b0e1-8fa9-40f4-b89d-f1038a1befaa" />

<img width="558" height="355" alt="image" src="https://github.com/user-attachments/assets/1e68c48e-c753-49b1-80f3-baf51ec5b345" />

The script installed OpenSSH Server and wrote a proof file to the `/tmp` directory to verify successful execution.


## Result
The proof-of-concept test confirmed that basic system configuration tasks
can be handled by scripts instead of storing all settings in machine images.
