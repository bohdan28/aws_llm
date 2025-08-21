# Bastion SSH Config Role

This Ansible role configures a bastion host as an SSH jump host, allowing secure access to private EC2 instances in a VPC.

## Requirements

- Ansible 2.9 or higher
- A bastion host with public IP address
- Private EC2 instances in a VPC (10.0.0.0/16 subnet)
- SSH key pair for accessing the instances

## Role Variables

Variables are defined in `defaults/main.yml`:

```yaml
private_instances:
  - name: private-instance-1
    hostname: 10.0.1.10
    user: ec2-user
  - name: private-instance-2
    hostname: 10.0.1.11
    user: ec2-user

private_key_path: ~/.ssh/private-key.pem
ssh_port: 22
bastion_user: "{{ ansible_user }}"
```

## Usage

1. Configure the variables in `defaults/main.yml` or override them in your playbook
2. Include the role in your playbook:

```yaml
- hosts: bastion
  roles:
    - bastion_ssh_config
```

3. After running the playbook, you can connect to private instances through the bastion:

```bash
ssh private-instance-1
```

## Features

- Configures SSH jump host settings
- Sets up SSH agent forwarding
- Enables TCP forwarding
- Configures connection persistence
- Sets up SSH keepalive settings
- Manages SSH server configuration

## Security Notes

- The role disables StrictHostKeyChecking and clears UserKnownHostsFile for private instances
- SSH agent forwarding is enabled by default
- Make sure to protect your SSH private keys and bastion host access 