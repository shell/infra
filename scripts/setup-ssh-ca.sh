#!/bin/bash
# Setup SSH Certificate Authority for homelab
set -e

# Set SOPS age key location if not already set
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

echo "=== SSH Certificate Authority Setup ==="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CA_DIR="$REPO_DIR/ansible/ssh-ca"

# Check for required tools
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "ERROR: $1 is not installed."
        echo "Install with: $2"
        exit 1
    fi
}

check_tool "ssh-keygen" "openssh"
check_tool "sops" "brew install sops"

# Create CA directory
mkdir -p "$CA_DIR"

# Check if CA already exists
if [ -f "$CA_DIR/ca_key.pub" ]; then
    echo "CA key already exists at $CA_DIR/ca_key.pub"
    echo ""
    cat "$CA_DIR/ca_key.pub"
    echo ""
    echo "To regenerate, remove $CA_DIR/ca_key* first"
    exit 0
fi

echo "Generating SSH CA key pair..."
echo ""

# Generate CA key pair (ED25519 for security and performance)
ssh-keygen -t ed25519 -f "$CA_DIR/ca_key" -N "" -C "homelab-ssh-ca"

echo ""
echo "CA key pair generated:"
echo "  Private key: $CA_DIR/ca_key"
echo "  Public key:  $CA_DIR/ca_key.pub"
echo ""

# Encrypt private key with SOPS
echo "Encrypting private key with SOPS..."
sops --encrypt "$CA_DIR/ca_key" > "$CA_DIR/ca_key.enc"
echo "Encrypted key: $CA_DIR/ca_key.enc"
echo ""

# Remove unencrypted private key
rm "$CA_DIR/ca_key"
echo "Removed unencrypted private key (kept encrypted version)"
echo ""

echo "=== CA Public Key ==="
cat "$CA_DIR/ca_key.pub"
echo ""

echo "=== Next Steps ==="
echo ""
echo "1. Configure hosts to trust this CA:"
echo "   cd $REPO_DIR/ansible && ansible-playbook playbooks/configure-ssh-ca.yml"
echo ""
echo "2. Sign a user's SSH key:"
echo "   $SCRIPT_DIR/sign-ssh-key.sh ~/.ssh/id_ed25519.pub <username>"
echo ""
echo "3. The signed certificate will be at ~/.ssh/id_ed25519-cert.pub"
echo "   SSH will automatically use it when connecting"
echo ""
echo "=== Done ==="
