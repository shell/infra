# Homelab infrastructure

Infrastructure as code for my homelab: Docker Compose stacks deployed with Ansible, a Talos Kubernetes cluster managed by Flux, and Cloudflare DNS via Terraform. Secrets are SOPS/age-encrypted.

This GitHub repo is a read-only push mirror of the primary repo on a self-hosted Forgejo instance (see [`docs/forgejo.md`](../docs/forgejo.md)). Issues and pull requests here aren't monitored, and pushes made directly here are overwritten by the next sync.

All CI/CD runs on Forgejo Actions inside the homelab (`.forgejo/workflows/`). GitHub Actions is disabled for this repo.
