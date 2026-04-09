#wolf-rack

A production-grade, heterogeneous Linux cluster built to demonstrate both my Unix/Linux capabilites as well as my systems architectural designe capabilites.

| Node | OS | Database | Focus |
|------|----|----------|-------|
| wolf-debian | Debian 12 | PostgreSQL 17+ | High Availability via Patroni + etcd |
| wolf-oracle | Oracle Linux 9 | Oracle 23ai Free | Enterprise hardening, UEK tuning |
| wolf-fedora | Fedora 43 | MariaDB/MongoDB | SELinux enforcement, innovation node |


## Stack

- **Orchestration:** LXD (container management)
- **IaC:** Terraform (infrastructure declaration)
- **Configuration:** Ansible (OS hardening, DB deployment)
- **Observability:** Prometheus + Grafana
- **HA:** Patroni + etcd (automated failover)
- **Security:** ED25519 SSH, AppArmor, SELinux, STIG/CIS hardening

## Control Plane

WSL2 Debian acting as the SRE control plane managing all three nodes.

## Skills Demonstrated

- Cross-platform Linux administration
- Infrastructure as Code (idempotent, repeatable builds)
- Zero-downtime rolling patches across heterogeneous kernels
- Automated database failover and chaos engineering
- Unified observability across disparate systems
