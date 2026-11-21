#!/bin/bash
# Encrypt all .env files using SOPS
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$REPO_ROOT"

echo "=== Encrypting secrets with SOPS ==="
echo ""

# Check if SOPS is configured (look for a real age key, not placeholder)
if ! grep -q "age1[a-z0-9]\{58\}" .sops.yaml 2>/dev/null; then
    echo "ERROR: SOPS not configured. Run ./scripts/setup-sops.sh first"
    exit 1
fi

# Find all .env files (excluding .env.example and .env.enc)
ENV_FILES=$(find cluster -name ".env" -type f ! -name "*.example" ! -name "*.enc" 2>/dev/null)

if [ -z "$ENV_FILES" ]; then
    echo "No .env files found to encrypt"
    exit 0
fi

echo "Found .env files:"
echo "$ENV_FILES"
echo ""

for env_file in $ENV_FILES; do
    enc_file="${env_file}.enc"

    if [ -f "$enc_file" ]; then
        echo "SKIP: $enc_file already exists"
    else
        echo "Encrypting: $env_file -> $enc_file"
        sops --encrypt "$env_file" > "$enc_file"
    fi
done

# Encrypt cluster *.secret.yml files in place (SOPS rule already covers this
# path pattern in .sops.yaml — this just automates running `sops -e -i`)
SECRET_YML_FILES=$(find cluster -name "*.secret.yml" -type f 2>/dev/null)

if [ -n "$SECRET_YML_FILES" ]; then
    echo "Found *.secret.yml files:"
    echo "$SECRET_YML_FILES"
    echo ""
    for secret_file in $SECRET_YML_FILES; do
        if sops --decrypt "$secret_file" > /dev/null 2>&1; then
            echo "SKIP: $secret_file already encrypted"
        else
            echo "Encrypting in place: $secret_file"
            sops --encrypt --in-place "$secret_file"
        fi
    done
fi

# Also handle alertmanager.yml
ALERTMANAGER="cluster/monitor/prometheus/alertmanager/alertmanager.yml"
if [ -f "$ALERTMANAGER" ] && [ ! -f "${ALERTMANAGER}.enc" ]; then
    echo "Encrypting: $ALERTMANAGER"
    sops --encrypt "$ALERTMANAGER" > "${ALERTMANAGER}.enc"
fi

# Encrypt terraform secrets
TFVARS_FILES=$(find terraform -name "secrets.auto.tfvars" -type f 2>/dev/null)
for tfvars in $TFVARS_FILES; do
    enc_file="${tfvars}.enc"
    if [ -f "$enc_file" ]; then
        echo "SKIP: $enc_file already exists"
    else
        echo "Encrypting: $tfvars -> $enc_file"
        sops --encrypt "$tfvars" > "$enc_file"
    fi
done

echo ""
echo "=== Encryption complete ==="
echo ""
echo "Encrypted files are ready to commit to git."
echo "Original .env files are gitignored and safe to keep locally."
echo ""
echo "To edit an encrypted file:"
echo "  sops cluster/ts-router/traefik/.env.enc"
