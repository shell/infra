# Ansible Automation for Homelab

This directory contains Ansible playbooks for deploying and managing the homelab infrastructure.

## Prerequisites

```bash
# Install Ansible
brew install ansible

# Install SOPS and age (for secrets)
brew install sops age

# GNU tar (prometheus.prometheus roles unpack archives on the controller)
brew install gnu-tar

# Galaxy collections (pinned)
ansible-galaxy collection install -r requirements.yml

# Set up SOPS encryption key
./scripts/setup-sops.sh
```

## Inventory

Hosts are defined in `inventory/hosts.yml`:

**LAN Docker Hosts:**

| Host | IP | Role |
|------|-----|------|
| ts-router | 192.168.10.141 | Traefik, Authelia, routing |
| servarr | 192.168.10.142 | Media stack (*arr, Jellyfin) |
| tools | 192.168.10.143 | Utilities (no services; apps moved to k8s) |
| monitor | 192.168.10.230 | Monitoring (Prometheus, Grafana) |

**VPS Hosts (Hostinger):**

| Host | IP | SSH Port | Services |
|------|-----|----------|----------|
| srv1517572 | <VPS_IP> | 22922 | Traefik, Jitsi Meet |

## Quick Start

```bash
cd ansible

# Test connectivity
ansible all -m ping

# Check status of all hosts
ansible-playbook playbooks/status.yml

# Deploy everything
ansible-playbook playbooks/deploy.yml

# Deploy to specific host
ansible-playbook playbooks/deploy.yml -l servarr

# Sync secrets only
ansible-playbook playbooks/sync-secrets.yml

# Restart a service
ansible-playbook playbooks/restart-service.yml -l ts-router -e service=traefik
```

## Playbooks

### Deployment

| Playbook | Description |
|----------|-------------|
| `deploy.yml` | Full deployment - copies files, decrypts secrets, runs docker compose |
| `sync-secrets.yml` | Only sync decrypted secrets to hosts |
| `status.yml` | Check container status and disk space |
| `restart-service.yml` | Restart a specific service |

### Monitoring Agents

`playbooks/monitoring.yml` installs the monitoring agents as **native systemd services** (no Docker needed) on every host in the `monitored` group, and regenerates Prometheus scrape targets on `monitor`. It also runs at the end of `deploy.yml`, and from GitHub Actions via **Deploy → action: monitoring**.

| Agent | Installed by (Galaxy) | Notes |
|-------|----------------------|-------|
| `beszel_agent` | `community.beszel.agent` | WebSocket to the hub with the universal token (auto-registers), SSH listener off, in `docker` group for container stats |
| `node_exporter` | `prometheus.prometheus.node_exporter` | Port 9100, opened in UFW for LAN + Docker subnets where UFW is active |

Collection versions are pinned in `requirements.yml`, and agent versions in `group_vars/monitored.yml`. To upgrade, bump the version in a commit and redeploy.

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml   # once / after bumps

ansible-playbook playbooks/monitoring.yml               # all hosts
ansible-playbook playbooks/monitoring.yml -l tools      # one host
ansible-playbook playbooks/monitoring.yml --check --diff
```

**New Linux box:** add it to `inventory/hosts.yml` under `monitored` (or `docker_hosts` if it also runs compose stacks), make sure it has passwordless sudo (`setup-sudoers.yml`), then run the playbook with `-l <box>` (or the GitHub Action). Beszel registers it automatically; Prometheus picks it up from the generated `targets/node-exporter.yml`.

**Which agents a host gets:** `monitoring_agents` in `group_vars/monitored.yml`, override per host in `host_vars/`.

**Adding a new monitoring tool:**
1. Add its collection to `requirements.yml` (e.g. `prometheus.prometheus` already ships blackbox, smartctl, process exporters, …)
2. Create `roles/monitoring_agents/agents/<name>/main.yml`, usually a single `include_role` of the collection role with vars from inventory. Secrets from `secrets/monitoring.secret.yml` are available as `monitoring_secrets.*`
3. Add `<name>` to `monitoring_agents` and its settings to `group_vars/monitored.yml`

Shared agent secrets: `sops secrets/monitoring.secret.yml`.

### Maintenance

| Playbook | Description |
|----------|-------------|
| `host-cleanup.yml` | Journal trimming, apt cache, tmp files, old kernels |
| `docker-cleanup.yml` | Prune images, volumes, networks, build cache |
| `proxmox-health.yml` | SMART checks, storage health, LVM/ZFS, temperatures |
| `maintenance-all.yml` | Wrapper: docker-cleanup + host-cleanup + proxmox-health |
| `update-systems.yml` | apt upgrade + rolling reboot for Docker VMs |
| `update-proxmox.yml` | Proxmox host updates + reboot notification |
| `proxmox-backup.yml` | PBS storage, nightly VM backup job, data-disk exclusions, Telegram failure alert (see `docs/proxmox-backup.md`) |
| `proxmox-metrics.yml` | PVE metric server → InfluxDB on monitor (token from `cluster/monitor/influxdb/.env.enc`); Grafana dashboard `proxmox-flux`. Forgejo: **Deploy → action: proxmox-metrics** |
| `security-hardening.yml` | SSH hardening, fail2ban, unattended-upgrades, then imports `firewall.yml` |
| `firewall.yml` | Declarative UFW, default-deny for host **and** Docker-published ports (`DOCKER-USER` hook in `after.rules`). Rules in `firewall_common_rules` / host_vars `firewall_rules`; Forgejo **Deploy → action: firewall** |

```bash
cd ansible

# Weekly cleanup
ansible-playbook playbooks/docker-cleanup.yml
ansible-playbook playbooks/host-cleanup.yml -K

# Health check
ansible-playbook playbooks/proxmox-health.yml

# Run all safe maintenance
ansible-playbook playbooks/maintenance-all.yml -K

# System updates (rolling reboot, one host at a time)
ansible-playbook playbooks/update-systems.yml -K

# Proxmox updates (never auto-reboots)
ansible-playbook playbooks/update-proxmox.yml

# Security hardening (run once, then after new VMs)
ansible-playbook playbooks/security-hardening.yml -K

# Send Telegram notifications
ansible-playbook playbooks/host-cleanup.yml -K -e notify_telegram=true
```

### VPS Management

| Playbook | Description |
|----------|-------------|
| `vps-bootstrap.yml` | One-shot fresh VPS init (run as root on port 22) |
| `vps-docker-setup.yml` | Install Docker CE + Compose plugin |
| `vps-deploy.yml` | Deploy Docker Compose services to VPS hosts |
| `vps-harden.yml` | Idempotent security hardening (SSH, UFW, fail2ban, MOTD) |

```bash
cd ansible

# Bootstrap new VPS (one-time):
ansible-playbook playbooks/vps-bootstrap.yml -l srv1517572 \
  -e "ansible_port=22 ansible_user=root" \
  -e "vps_fail2ban_ignoreip='127.0.0.1/8 ::1 $(curl -4 -s ifconfig.me)'"

# Install Docker (one-time):
ansible-playbook playbooks/vps-docker-setup.yml -l srv1517572

# Deploy services:
ansible-playbook playbooks/vps-deploy.yml -l srv1517572

# Deploy single service:
ansible-playbook playbooks/vps-deploy.yml -l srv1517572 -e service=jitsi

# Re-harden / update:
ansible-playbook playbooks/vps-harden.yml -l srv1517572
```

> VPS service configs live in `cloud/hostinger/<hostname>/` — see [cloud/hostinger/README.md](/cloud/hostinger/README.md) for details.

### Scheduled Runs (GitHub Actions)

| Playbook | Schedule | Frequency |
|----------|----------|-----------|
| `docker-cleanup.yml` + `host-cleanup.yml` | Sunday 4am UTC | Weekly |
| `proxmox-health.yml` | 5am UTC | Daily |
| `update-systems.yml` | — | Manual only |
| `update-proxmox.yml` | — | Manual only |
| `security-hardening.yml` | — | Manual only |

## Secrets Management

Secrets are encrypted with SOPS using age encryption.

```bash
# Encrypt a new .env file
sops --encrypt cluster/path/to/.env > cluster/path/to/.env.enc

# Edit an encrypted file (decrypts in editor, re-encrypts on save)
sops cluster/path/to/.env.enc

# Decrypt to stdout
sops --decrypt cluster/path/to/.env.enc

# Encrypt all .env files at once
./scripts/encrypt-secrets.sh
```

### File Convention

- `.env` - Plaintext secrets (gitignored, local only)
- `.env.enc` - Encrypted secrets (committed to git)
- `.env.example` - Template with placeholder values (committed)

## Adding a New Service

1. Create the service directory in `cluster/<host>/`
2. Add docker-compose file
3. Create `.env` with secrets
4. Encrypt: `sops --encrypt cluster/<host>/service/.env > cluster/<host>/service/.env.enc`
5. Add to `inventory/hosts.yml` under the host's `docker_compose_dirs`
6. Deploy: `ansible-playbook playbooks/deploy.yml -l <host>`

## Grafana Dashboards

Dashboards are provisioned from JSON files in `cluster/monitor/grafana/config/dashboards/` (see `config/dashboards.yml`), so they're version-controlled and survive redeploys instead of only living in the gitignored `data/` sqlite DB.

```bash
# Add a new community dashboard (find IDs at https://grafana.com/grafana/dashboards/)
./scripts/add-grafana-dashboard.sh <dashboard-id> [output-name]

# Update an existing one to the latest revision
./scripts/add-grafana-dashboard.sh --update <existing-name>
```

The script rewrites any `${DS_PROMETHEUS}` / `${ds_prometheus}` placeholder to the fixed `prometheus` datasource uid (see `config/datasource.yml`), since that placeholder is only resolved by Grafana's UI import flow, not file-based provisioning. After running it, `git add` the new/updated file and deploy as usual.

## SSH Setup

Ensure you can SSH to all hosts without a password:

```bash
# Copy your SSH key to each host
ssh-copy-id vlad@192.168.10.141
ssh-copy-id vlad@192.168.10.142
ssh-copy-id vlad@192.168.10.143
ssh-copy-id vlad@192.168.10.230
```

## Directory Structure

```
ansible/
├── ansible.cfg          # Ansible configuration
├── requirements.yml     # Pinned Galaxy collections
├── inventory/
│   ├── hosts.yml        # Host definitions
│   ├── group_vars/
│   │   ├── all.yml          # Telegram config (all hosts)
│   │   ├── docker_hosts.yml # Update, cleanup, security vars
│   │   ├── monitored.yml    # Monitoring agents list + agent settings
│   │   ├── proxmox.yml      # Proxmox update/health vars
│   │   └── vps_hosts.yml    # VPS: SSH, fail2ban, UFW, packages
│   └── host_vars/
│       ├── ts-router.yml    # Tailscale firewall config
│       └── srv1517572.yml   # VPS: services, UFW ports, MOTD
├── playbooks/
│   ├── deploy.yml              # LAN: deploy Docker Compose services
│   ├── sync-secrets.yml        # LAN: secrets sync only
│   ├── status.yml              # LAN: check container status
│   ├── restart-service.yml     # LAN: restart a service
│   ├── monitoring.yml          # LAN: beszel-agent, node-exporter, Prometheus targets
│   ├── configure-ssh-ca.yml
│   ├── host-cleanup.yml
│   ├── docker-cleanup.yml
│   ├── proxmox-health.yml
│   ├── maintenance-all.yml
│   ├── update-systems.yml
│   ├── update-proxmox.yml
│   ├── security-hardening.yml  # LAN: SSH, UFW, fail2ban
│   ├── vps-bootstrap.yml       # VPS: one-shot init
│   ├── vps-docker-setup.yml    # VPS: install Docker
│   ├── vps-deploy.yml          # VPS: deploy Docker Compose services
│   ├── vps-harden.yml          # VPS: SSH, UFW, fail2ban, MOTD
│   └── templates/
│       ├── vps-motd-dashboard.sh.j2
│       └── vps-fail2ban-jail.local.j2
├── roles/
│   └── monitoring_agents/      # agents/<name>/main.yml per monitoring tool
└── secrets/
    └── monitoring.secret.yml   # sops-encrypted agent secrets
```
