# Installation
PostgreSQL 15 installed via Ansible playbook pg_install.yml.
Listening on all interfaces (0.0.0.0:5432).

## Replication User
Created via psql:
'''sql
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'wolfpack123';
'''

Verified with \du replicator - Replication attribute confirmed.

# Configuration Changes
- listen_addresses = '*' in postgresql.conf
- Replication rule added to pg_hba.conf for 10.33.214.0/24
EOF
