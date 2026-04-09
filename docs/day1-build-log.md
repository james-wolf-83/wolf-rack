## What I did
- Cleaned existing LXD setup/environment
- Built wolf-rack project structure
- Wrote Terraform declaration for 'three node heterogeneous cluster
- Initialized Terraform with lxd provider v2.7.0
- Applied infrastructure, all three nodes up in under 35 seconds
- Initialized git repository and pushed initial GitHub

## What I learned
- Terraform declares *what* infrastructure should exist, not *how* to build it
- `terraform plan` is a dry run — shows changes without applying them
- `terraform apply` makes reality match the declaration
- `terraform destroy` tears everything down cleanly
- In lxd provider v2.x the resource type is `lxd_instance` not `lxd_container`
- `.tfstate` files are sensitive and must never be pushed to GitHub

### LXD
- Images are read-only templates, containers are live instances created from them
- `lxc stop --all` and `lxc start --all` for session management
- Containers share the host kernel — lighter than VMs

### Git
- `.gitignore` protects sensitive and unnecessary files from being committed
- `git add .` stages all changes
- `git commit -m` creates a snapshot in history
- `git remote -v` confirms GitHub connection

## Commands Reference
```bash
# Start the rack
lxc start wolf-debian wolf-oracle wolf-fedora

# Check status
lxc list

# Stop the rack
lxc stop wolf-debian wolf-oracle wolf-fedora

# Rebuild from scratch
cd ~/wolf-rack/terraform
terraform destroy
terraform apply
```

## Node IPs (dynamic — check lxc list each session)
- wolf-debian: 10.33.214.x
- wolf-oracle: 10.33.214.x  
- wolf-fedora: 10.33.214.x

## Next Session
1. Generate ED25519 SSH keys on control plane
2. Push keys to all three nodes
3. Build Ansible inventory
4. Write base hardening playbook
