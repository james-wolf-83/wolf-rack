# Day 2 Build Log — April 9, 2026

## What I Did
- Diagnosed and resolved full container network outage — zero outbound connectivity on all nodes
- Removed ghost Docker installation that was poisoning iptables
- Identified correct outbound interface (eth1 not eth0) using `ip route show`
- Fixed NAT and FORWARD rules and persisted them with iptables-persistent
- Replaced wolf-oracle (repo timeouts) with wolf-suse (openSUSE 15.6)
- Replaced wolf-suse (DNS/netconfig fighting us) with wolf-alma (AlmaLinux 9)
- Installed openssh-server on all three nodes
- Generated ED25519 SSH keys on WSL2 control plane
- Pushed public key to all three nodes
- Verified passwordless SSH access to wolf-debian, wolf-fedora, wolf-alma
- Updated Terraform to reflect final node lineup
- Committed all changes to GitHub

---

## What I Learned

### Network Debugging
- Always test the lowest layer first — ICMP to a raw IP bypasses DNS and HTTP lies
- `ip route show` tells you the real outbound interface — never assume eth0
- iptables rules must reference the correct outbound interface or traffic silently drops
- Ghost chains from uninstalled software (Docker) survive removal and intercept traffic
- Always check `iptables -L FORWARD --line-numbers` when containers can't reach internet
- tcpdump on the bridge shows if packets are leaving the container
- Requests with no replies = routing/NAT problem, not a container problem
- iptables rules don't survive reboots — always persist with netfilter-persistent

### Cross-Platform Package Management
- Debian: `apt-get` — service name is `ssh`
- RHEL/AlmaLinux/Fedora: `dnf` — service name is `sshd`
- openSUSE: `zypper` — DNS managed by netconfig, fights manual resolv.conf changes
- Each distro has different repo structures, CDN reliability varies wildly

### SSH Key Authentication
- ED25519 is the modern standard — smaller, faster, more secure than RSA
- Public key goes in `/root/.ssh/authorized_keys` on each node
- Permissions matter: `.ssh` must be 700, `authorized_keys` must be 600
- LXD containers don't run sshd by default — must install and enable manually

### Terraform State Management
- Terraform tracks what it built in `.tfstate`
- When you manually delete a container Terraform knows on next `apply`
- `terraform apply` is idempotent — safe to run multiple times
- Replacing a node means updating `main.tf` and running `terraform apply`

### LXD
- `lxc exec <node> -- <command>` runs commands inside containers without SSH
- `lxc restart <node>` restarts a container cleanly
- DNS at the bridge level (`lxc network set`) propagates to all containers via DHCP
- `lxc delete <node>` permanently removes a container

---

## Network Fix — Final Working iptables Rules

```bash
# Flush existing rules
sudo iptables -F
sudo iptables -t nat -F

# NAT outbound traffic from containers
sudo iptables -t nat -A POSTROUTING -s 10.33.214.0/24 ! -d 10.33.214.0/24 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 10.33.214.0/24 -o eth1 -j MASQUERADE

# Allow forwarding between bridge and outbound interface
sudo iptables -A FORWARD -i lxdbr0 -o eth1 -j ACCEPT
sudo iptables -A FORWARD -i eth1 -o lxdbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Persist rules
sudo netfilter-persistent save
```

**Key insight:** Outbound interface is eth1 not eth0. Always verify with `ip route show` first.

---

## Network Diagnostic Toolkit

```bash
# Test raw connectivity bypassing DNS
lxc exec <node> -- ping -c 3 8.8.8.8

# Check interface addresses
lxc exec <node> -- ip addr show eth0

# Check routing table — find real outbound interface
ip route show

# Watch live traffic on bridge
sudo tcpdump -i lxdbr0 -n icmp

# Inspect forward chain with packet counters
sudo iptables -L FORWARD -v --line-numbers

# Check NAT rules
sudo iptables -t nat -L POSTROUTING -n -v
```

---

## Commands Reference

```bash
# Start the rack
lxc start --all

# Check status
lxc list

# Stop the rack
lxc stop --all

# SSH into nodes
ssh root@10.33.214.128   # wolf-debian
ssh root@10.33.214.16    # wolf-fedora
ssh root@10.33.214.189   # wolf-alma

# Rebuild from scratch
cd ~/wolf-rack/terraform
terraform destroy
terraform apply

# Run command inside container without SSH
lxc exec wolf-debian -- bash
```

---

## Final Node Lineup

| Node | OS | IP | SSH | Purpose |
|------|----|----|-----|---------|
| wolf-debian | Debian 12 | 10.33.214.128 | ✅ | PostgreSQL + Patroni |
| wolf-fedora | Fedora 43 | 10.33.214.16 | ✅ | MariaDB/MongoDB |
| wolf-alma | AlmaLinux 9 | 10.33.214.189 | ✅ | Enterprise RHEL clone |

**Note:** Node IPs are dynamic — check `lxc list` each session.

---

## Nodes Retired This Session

- **wolf-oracle** — Oracle Linux 9, retired due to persistent yum.oracle.com CDN timeouts
- **wolf-suse** — openSUSE Leap 15.6, retired due to netconfig DNS management conflicts in WSL2

Both are valid enterprise distros. The issues were environmental (WSL2 + CDN reliability) not architectural.

---

## What Survived the Chaos

- Terraform state correctly tracked all node changes
- Git history preserved every decision
- iptables rules persisted across restarts
- SSH keys survived node replacements

---

## Next Session

1. Build Ansible inventory file pointing at all three nodes
2. Write base hardening playbook — cross-platform, handles Debian/RHEL differences
3. Run first Ansible play against the rack
4. Begin PostgreSQL installation on wolf-debian

---

## Stack Reminder — Full wolf-rack Architecture

```
Terraform        — declares what exists
Ansible          — configures what's inside
Liquibase        — versions database schemas
Prometheus       — collects metrics
Grafana          — visualizes health
Patroni + etcd   — automated PostgreSQL failover
```

Liquibase sits above Ansible. Flow:
Terraform builds rack → Ansible installs DBs → Liquibase manages schema migrations
