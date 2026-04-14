# Day 3 Build Log — April 10, 2026

## What I Did
- Diagnosed persistent Fedora 43 repo timeout issues blocking openssh-server installation
- Made the decision to retire wolf-fedora and replace with wolf-rocky (Rocky Linux 9)
- Updated Terraform main.tf — replaced fedora_node resource with rocky_node
- Ran terraform apply — wolf-rocky created in 26 seconds
- Updated Ansible inventory hosts.yml with wolf-rocky IP and correct Python interpreter path
- Verified Python3 path differences across nodes
- Installed openssh-server on wolf-rocky via dnf
- Pushed ED25519 SSH key to wolf-rocky
- Enabled and started sshd on wolf-rocky
- Ran ansible -m ping all — all three nodes returned pong for the first time
- Committed inventory and changes to GitHub

---

## What I Learned

### Knowing When to Swap vs Fight
Fedora 43 mirrors were consistently timing out from WSL2 — three separate attempts across two days. The decision to swap to Rocky Linux 9 was the right call. In production you'd escalate or find a workaround. In a lab environment your time is better spent building than fighting infrastructure that's working against you. Rocky Linux is an enterprise RHEL clone that's rock solid and serves the same purpose in the portfolio.

### Terraform State Management
When you manually delete a container outside of Terraform, the state file still thinks it exists. Running terraform apply reconciles reality with the declaration — it sees wolf-fedora is gone, sees wolf-rocky needs to be created, and acts accordingly. This is Terraform doing exactly what it's designed to do.

### Python Interpreter Paths Vary by Distro
Ansible needs Python on the remote node to run modules. Different distros put Python in different locations. Always verify with `which python3` inside the container before setting `ansible_python_interpreter` in the inventory. Getting this wrong causes confusing "module not found" errors.

### Ansible Ad-Hoc Commands
`ansible -m ping all` is not a network ping — it's Ansible verifying SSH connectivity and Python availability on every host in the inventory simultaneously. All three returning pong means Ansible has full control of the rack.

---

## Commands Reference

```bash
# Replace a node — update main.tf then
cd ~/wolf-rack/terraform
terraform apply

# Verify Python path inside a container
lxc exec wolf-rocky -- which python3

# Install SSH on RHEL based node
lxc exec wolf-rocky -- dnf install -y openssh-server

# Push SSH key to new node
lxc exec wolf-rocky -- bash -c "mkdir -p /root/.ssh && chmod 700 /root/.ssh"
cat ~/.ssh/id_ed25519.pub | lxc exec wolf-rocky -- bash -c "cat >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"

# Enable and start sshd
lxc exec wolf-rocky -- systemctl enable --now sshd

# Test Ansible connectivity
ansible -i ~/wolf-rack/ansible/inventory/hosts.yml all -m ping
```

---

## Final Node Lineup After Day 3

| Node | OS | IP | SSH | Python |
|------|----|----|-----|--------|
| wolf-debian | Debian 12 | 10.33.214.128 | ✅ | /bin/python3 |
| wolf-rocky | Rocky Linux 9 | 10.33.214.248 | ✅ | /bin/python3 |
| wolf-alma | AlmaLinux 9 | 10.33.214.189 | ✅ | /bin/python3 |

---

## Nodes Retired

- **wolf-fedora** — Fedora 43, retired due to persistent dnf mirror timeouts from WSL2

---

## Next Session
1. Snapshot all three nodes before any changes
2. Write base hardening playbook
3. Run hardening across all three nodes simultaneously
4. Commit and document
