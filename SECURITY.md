# Security Guide

This document covers security practices and credential management for the homelab infrastructure.

## Current State

- Git repository initialized with `.gitignore` configured to exclude sensitive files
- Secrets are stored in `.env` files (excluded from git)
- `.env.example` templates are tracked for documentation

---

## Secret Locations

| Service | Secret File | Template |
|---------|-------------|----------|
| Traefik | `cluster/ts-router/traefik/.env` | `.env.example` |
| Nebula-sync | `cluster/ts-router/nebula-sync/.env` | `.env.example` |
| Homarr | `cluster/ts-router/dashboard/homarr/.env` | `.env.example` |
| Servarr Stack | `cluster/servarr/servarr/.env` | `.env.example` |
| Tube Archivist | `cluster/servarr/tubearchivist/.env` | `.env.example` |
| AlertManager | `cluster/monitor/prometheus/alertmanager/alertmanager.yml` | `alertmanager.yml.example` |

---

## Credential Rotation Reference

Use this section when you need to rotate credentials (routine maintenance or suspected compromise).

### Cloudflare API Token
```bash
# Location: cluster/ts-router/traefik/.env
# Generate at: https://dash.cloudflare.com/profile/api-tokens
# Permissions: Zone:DNS:Edit

CF_DNS_API_TOKEN=your_token_here

# After updating:
docker compose -f cluster/ts-router/traefik/compose.yaml restart
```

### Telegram Bot Token (AlertManager)
```bash
# Location: cluster/monitor/prometheus/alertmanager/alertmanager.yml
# Generate via @BotFather on Telegram

bot_token: 'your_bot_token'
chat_id: your_chat_id

# After updating:
docker compose restart alertmanager
```

### PIA VPN Credentials
```bash
# Location: cluster/servarr/servarr/.env
# Manage at: https://www.privateinternetaccess.com/account/client-control-panel

PIA_USER=your_username
PIA_PASS=your_password
```

---

## Best Practices

### Before Committing
```bash
# Always check what you're about to commit
git status
git diff --staged

# Verify no secrets in staged files
git diff --staged | grep -iE "(password|secret|token|key|api)"
```

### Generating Strong Passwords
```bash
# 32-character password
openssl rand -base64 32

# 48-character password
openssl rand -base64 36

# URL-safe password (no special chars)
openssl rand -hex 24
```

### Rotation Schedule
| Frequency | What to Rotate |
|-----------|----------------|
| Quarterly | API tokens, service accounts |
| Annually | Database passwords, encryption keys |
| Immediately | After any suspected compromise |

### Backup Before Changes
```bash
# Backup all .env files
for f in $(find . -name ".env" -type f); do
  cp "$f" "${f}.backup.$(date +%Y%m%d)"
done
```

---

## Verifying Services After Changes

```bash
# Check all containers are running
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check Traefik logs
docker logs traefik 2>&1 | tail -50

# Test Authelia
curl -sI https://auth.sf.penk.in | head -5

# Test AlertManager (send test notification)
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"TestAlert"}}]'
```

---

## Security Architecture

### Network Security
- All external traffic routes through Traefik reverse proxy
- HTTPS enforced with automatic Let's Encrypt certificates via Cloudflare DNS
- Authelia SSO protects sensitive services (*arr stack, monitoring)
- Internal services communicate over Docker networks

### Docker Security
- Docker socket access via `docker-socket-proxy` (limited API exposure)
- Containers run with `no-new-privileges` where possible
- TLS verification only disabled for specific self-signed backends (Proxmox, Synology)

### Access Control
- Authelia provides centralized authentication
- Forward auth middleware on Traefik routes
- IP whitelist middleware available for additional restriction

---

Test commig signing

---
## Incident Response

If you suspect a security breach:

1. **Contain** - Disable external access via Cloudflare or firewall
2. **Assess** - Check logs in Authelia, Traefik, and affected services
3. **Rotate** - Change all potentially compromised credentials
4. **Monitor** - Watch for continued unauthorized activity
5. **Review** - Identify how the breach occurred and prevent recurrence
