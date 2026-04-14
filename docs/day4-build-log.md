# Day 4 Build Log — April 12, 2026

## What I Did
- Snapshotted all three nodes before hardening (pre-hardening snapshot)
- Created Ansible playbook directory structure
- Wrote base hardening playbook from scratch — hardening.yml
- Debugged and resolved firewalld hanging issue in LXD containers
- Debugged and resolved SSH restart hanging on wolf-alma (LXD drop-in override)
- Successfully ran hardening playbook against wolf-debian and wolf-rocky
- SSH configuration hardened on wolf-debian and wolf-rocky
- Login banner deployed to wolf-debian and wolf-rocky
- Identified wolf-alma one-line fix for next session
- Committed playbook to GitHub

---

## What I Learned

### Ansible Playbook Structure
A playbook is a YAML list. The play starts with a dash and everything inside it is indented two spaces. Tasks are indented four spaces. Task arguments are indented six spaces. YAML is whitespace sensitive — one wrong space breaks everything.

The three main sections of a play are the header (name, hosts, become), vars for reusable variables, and tasks for what to actually do.

### Ansible Modules
Modules are Ansible's built-in tools. Instead of writing distro-specific commands you use a module and Ansible figures out the right approach for the OS it's talking to.

The `package` module installs packages and automatically uses apt on Debian or dnf on RHEL-based systems. The `service` module manages services. The `lineinfile` module edits specific lines in a file using regex matching. The `copy` module writes content to a file.

### The lineinfile Module
This is how Ansible edits configuration files safely. The `regexp` field finds the existing line using a pattern. The `line` field replaces it with exactly what you want. Using `loop` runs the same task multiple times with different values — one iteration per setting. Without loop you'd need five separate tasks for five SSH settings.

### Ansible Facts
When Ansible connects to a host it automatically gathers facts — built-in variables about the system. `ansible_os_family` returns "Debian" for Debian-based systems and "RedHat" for RHEL-based systems. Using `when: ansible_os_family == "RedHat"` makes a task conditional so it only runs on the right nodes.

### Idempotency in Practice
Running the playbook multiple times is safe. Ansible checks the current state before making changes. If SSH config is already hardened it reports `ok` not `changed` and moves on. Nothing gets broken by running it again.

### LXD Container Limitations
LXD injects its own systemd drop-in configuration into containers via `zzz-lxc-service.conf`. This can interfere with service restarts — particularly sshd — causing Ansible to hang waiting for a response that never comes. The workaround is to either skip the restart entirely (config changes apply to new connections automatically) or exclude the affected node using `inventory_hostname !=`.

firewalld also hangs in LXD containers because it requires dbus which isn't fully available in the container environment. The correct approach is to configure firewall rules after databases are installed so you know exactly what ports to open.

### SSH Hardening Settings Applied
These settings were written to /etc/ssh/sshd_config on wolf-debian and wolf-rocky:

`PermitRootLogin prohibit-password` — root login allowed only with SSH key, password blocked.

`PasswordAuthentication no` — all password authentication disabled, SSH key only.

`X11Forwarding no` — graphical display forwarding disabled, removes attack surface.

`ClientAliveInterval 300` — server sends keepalive check after 5 minutes of idle.

`ClientAliveCountMax 2` — after 2 failed keepalives the session is dropped. Maximum idle session time is 10 minutes.

---

## Commands Reference

```bash
# Snapshot all nodes before changes
lxc snapshot wolf-debian pre-hardening
lxc snapshot wolf-alma pre-hardening
lxc snapshot wolf-rocky pre-hardening

# Verify snapshots
lxc info wolf-debian

# Run hardening playbook
ansible-playbook -i ~/wolf-rack/ansible/inventory/hosts.yml ~/wolf-rack/ansible/playbooks/hardening.yml

# Roll back a node if playbook breaks something
lxc restore wolf-debian pre-hardening

# Verify SSH config was applied
lxc exec wolf-debian -- cat /etc/ssh/sshd_config | grep PermitRootLogin
lxc exec wolf-debian -- cat /etc/motd
```

---

## Hardening Status

| Node | SSH Installed | SSH Config Hardened | Banner Set | Restart Complete |
|------|--------------|---------------------|------------|-----------------|
| wolf-debian | ✅ | ✅ | ✅ | ✅ |
| wolf-rocky | ✅ | ✅ | ✅ | ✅ |
| wolf-alma | ✅ | ✅ | ✅ | ❌ pending fix |

wolf-alma fix — add `inventory_hostname != "wolf-alma"` condition to the RedHat restart task. SSH config changes are already written and will apply to new connections. One line change, five minute fix next session.

---

## Playbook Location
```
~/wolf-rack/ansible/playbooks/hardening.yml
```

---

## Next Session
1. Fix wolf-alma SSH restart condition — one line change
2. Run final hardening playbook — all three nodes complete
3. Verify hardening on all three nodes
4. Begin PostgreSQL installation on wolf-debian
5. This is where wolf-rack starts becoming a real database infrastructure environment
