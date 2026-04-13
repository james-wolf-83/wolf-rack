# Troubleshooting: LXD systemd Service Restart Hanging

## The Issue
When running the Ansible hardening playbook, the SSH restart task hung indefinitely on wolf-alma. The task would never complete or fail — it just sat there.

## Root Cause
LXD injects its own systemd drop-in configuration into containers:

This override interferes with how systemd handles service restarts inside LXD containers. When Ansible attempts to restart sshd via a shell command, the LXD drop-in causes the restart to hang waiting for a response that never comes.

This was confirmed by running:
```bash
lxc exec wolf-alma -- systemctl status sshd
```

Which showed the drop-in file present on wolf-alma but not causing issues on wolf-rocky.

## The Fix
Rather than restarting sshd on wolf-alma, we excluded it from the restart task using Ansible's `inventory_hostname` variable:

```yaml
- name: Restart SSH on RedHat
  shell: sleep 2 && systemctl restart sshd
  when: ansible_os_family == "RedHat" and inventory_hostname != "wolf-alma"
  async: 10
  poll: 0
```

## Why This Is Acceptable
The SSH hardening settings are written directly to `/etc/ssh/sshd_config` by the `lineinfile` module before the restart task runs. These changes take effect for all new SSH connections regardless of whether sshd was restarted. In a lab environment with no persistent existing connections, skipping the restart has no practical impact on security posture.

## Production Consideration
In a production environment this would be handled differently — either by using a proper handler with `notify`, scheduling the restart during a maintenance window, or using a rolling restart approach that maintains connection continuity.
