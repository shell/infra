# VPS Infrastructure — Hostinger

Docker Compose services running on public-facing Hostinger VPS machines. Each host has its own directory with independent service configs.

## Hosts

| Host | IP | SSH Port | Services |
|------|-----|----------|----------|
| srv1517572 | <VPS_IP> | 22922 | Traefik, Jitsi Meet, penk.in preview |

## Quick Reference

```bash
cd ansible

# Bootstrap a NEW VPS (one-time, as root):
ansible-playbook playbooks/vps-bootstrap.yml -l srv1517572 \
  -e "ansible_port=22 ansible_user=root" \
  -e "vps_fail2ban_ignoreip='127.0.0.1/8 ::1 $(curl -4 -s ifconfig.me)'"

# Install Docker (one-time):
ansible-playbook playbooks/vps-docker-setup.yml -l srv1517572

# Deploy services:
ansible-playbook playbooks/vps-deploy.yml -l srv1517572

# Deploy single service:
ansible-playbook playbooks/vps-deploy.yml -l srv1517572 -e service=traefik

# Re-harden / apply security updates:
ansible-playbook playbooks/vps-harden.yml -l srv1517572
```

## Services

### penk.in preview

- **Config**: `srv1517572/penk-in/`
- **URL**: https://new.penk.in
- **Image**: `ghcr.io/shell/penk.in`, pinned to redesign commit `84afb2e7d7529a232bba7afc6bd31150cfdb98de`
- **Deploy**: `ansible-playbook playbooks/vps-deploy.yml -l srv1517572 -e service=penk-in` from `ansible/`
- **Rollback**: set `PENK_IN_TAG=<previous published SHA>` in `/home/vlad/penk-in/.env`, then run `docker compose pull && docker compose up -d` in that directory.
- **DNS**: unproxied A record `new.penk.in` to `<VPS_IP>`; TLS uses Traefik's existing Cloudflare certificate resolver.
- Automatic deployment and the main domain cutover are separate follow-up changes.

### Traefik (Reverse Proxy)

- **Config**: `srv1517572/traefik/`
- **Purpose**: TLS termination, routes traffic to Docker services by subdomain
- **Certs**: Per-service Let's Encrypt via Cloudflare DNS challenge
- **Dashboard**: Localhost only — access via SSH tunnel:
  ```bash
  ssh -L 8080:127.0.0.1:8080 vlad@<VPS_IP> -p 22922
  # Open http://localhost:8080
  ```

### Jitsi Meet

- **Config**: `srv1517572/jitsi/`
- **URL**: https://meet.penk.in
- **Auth**: Registered users create meetings, guests join via link
- **Branding**: "VA Family"
- **Ports**: 443/tcp (via Traefik), 10000/udp (JVB direct)
- **Image**: `ghcr.io/jitsi/*:stable-11248-1` (rootless; containers run as uid 1000)

**Manage users:**
```bash
ssh vlad@<VPS_IP> -p 22922

# Add user:
docker exec -it jitsi-prosody prosodyctl --config /run/prosody/config/prosody.cfg.lua register USERNAME meet.jitsi PASSWORD

# Remove user:
docker exec -it jitsi-prosody prosodyctl --config /run/prosody/config/prosody.cfg.lua unregister USERNAME meet.jitsi

# List users:
docker exec -it jitsi-prosody prosodyctl --config /run/prosody/config/prosody.cfg.lua shell
> user:list("meet.jitsi")
```

## Adding a New Service

1. Create directory: `cloud/hostinger/<host>/<service>/`
2. Add `compose.yaml` with Traefik labels:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.myservice.rule=Host(`myservice.penk.in`)"
     - "traefik.http.routers.myservice.entrypoints=https"
     - "traefik.http.routers.myservice.tls.certresolver=cloudflare"
     - "traefik.docker.network=proxy"
   networks:
     - proxy
   ```
3. Create `.env.example` and encrypt secrets:
   ```bash
   sops --encrypt --input-type dotenv --output-type dotenv .env > .env.enc
   rm .env
   ```
4. Add service to `ansible/inventory/host_vars/<host>.yml`:
   ```yaml
   docker_compose_dirs:
     - traefik
     - jitsi
     - myservice  # add here
   ```
5. Add DNS record to `terraform/cloudflare/dns.tf`:
   ```hcl
   resource "cloudflare_record" "myservice_penkin" {
     comment = "My Service on Hostinger VPS"
     content = "<VPS_IP>"
     name    = "myservice"
     proxied = false
     ttl     = 300
     type    = "A"
     zone_id = var.zone_id
   }
   ```
6. Deploy:
   ```bash
   cd ansible
   ansible-playbook playbooks/vps-deploy.yml -l srv1517572 -e service=myservice
   cd ../terraform/cloudflare
   terraform apply
   ```

## Adding a New VPS Host

1. Create VPS in Hostinger panel, add SSH key
2. Add to `ansible/inventory/hosts.yml` under `vps_hosts`
3. Create `ansible/inventory/host_vars/<hostname>.yml`
4. Bootstrap:
   ```bash
   ansible-playbook playbooks/vps-bootstrap.yml -l <hostname> \
     -e "ansible_port=22 ansible_user=root" \
     -e "vps_fail2ban_ignoreip='127.0.0.1/8 ::1 $(curl -4 -s ifconfig.me)'"
   ansible-playbook playbooks/vps-docker-setup.yml -l <hostname>
   ```
5. Create service directories under `cloud/hostinger/<hostname>/`
6. Copy Traefik config from an existing host, update `.env` with new CF token

## Directory Structure

```
cloud/hostinger/
├── README.md                       # This file
└── srv1517572/                     # Hostinger VPS
    ├── traefik/
    │   ├── compose.yaml            # Traefik + docker-socket-proxy
    │   ├── data/
    │   │   └── traefik.yml         # Static config
    │   ├── .env.example
    │   └── .env.enc                # Encrypted CF_DNS_API_TOKEN
    └── jitsi/
        ├── compose.yaml            # web, prosody, jicofo, jvb
        ├── .env.example
        └── .env.enc                # Encrypted XMPP passwords
```

## Secrets

Same SOPS/age pattern as homelab. See [SECURITY.md](/SECURITY.md) for details.

```bash
# Encrypt:
sops --encrypt --input-type dotenv --output-type dotenv .env > .env.enc

# Decrypt:
sops --decrypt --input-type dotenv --output-type dotenv .env.enc

# Edit in-place:
sops .env.enc
```

## Persistent Data

Jitsi config persists at `/home/vlad/.jitsi-meet-cfg/` on the VPS (owned by uid 1000). User accounts live in `storage/prosody/data/`; back that up to preserve them. This survives `docker compose down` and redeployments.

Traefik certificates persist at `/home/vlad/traefik/data/acme.json`. This file is created automatically and should not be deleted (forces cert re-issuance, subject to Let's Encrypt rate limits).
