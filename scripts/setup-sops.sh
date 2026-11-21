#!/bin/bash
# Setup SOPS with age encryption for homelab secrets
set -e

echo "=== SOPS + age Setup Script ==="
echo ""

# Check for required tools
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "ERROR: $1 is not installed."
        echo "Install with: $2"
        exit 1
    fi
}

# Check dependencies
check_tool "sops" "brew install sops"
check_tool "age" "brew install age"

# Create age key directory
AGE_KEY_DIR="$HOME/.config/sops/age"
AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"

if [ -f "$AGE_KEY_FILE" ]; then
    echo "Age key already exists at $AGE_KEY_FILE"
    PUBLIC_KEY=$(grep "public key:" "$AGE_KEY_FILE" | cut -d: -f2 | tr -d ' ')
else
    echo "Creating new age key..."
    mkdir -p "$AGE_KEY_DIR"
    age-keygen -o "$AGE_KEY_FILE" 2>&1
    chmod 600 "$AGE_KEY_FILE"
    PUBLIC_KEY=$(grep "public key:" "$AGE_KEY_FILE" | cut -d: -f2 | tr -d ' ')
    echo ""
    echo "Key created at: $AGE_KEY_FILE"
fi

echo ""
echo "=== Your age public key ==="
echo "$PUBLIC_KEY"
echo ""

# Update .sops.yaml with the public key
SOPS_CONFIG="$(dirname "$0")/../.sops.yaml"
if [ -f "$SOPS_CONFIG" ]; then
    echo "Updating .sops.yaml with your public key..."
    sed -i.bak "s/age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/$PUBLIC_KEY/g" "$SOPS_CONFIG"
    rm -f "${SOPS_CONFIG}.bak"
    echo "Updated: $SOPS_CONFIG"
fi

echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Encrypt existing .env files:"
echo "   cd $(dirname "$0")/.."
echo "   sops --encrypt cluster/ts-router/traefik/.env > cluster/ts-router/traefik/.env.enc"
echo ""
echo "2. Edit encrypted files directly:"
echo "   sops cluster/ts-router/traefik/.env.enc"
echo ""
echo "3. Decrypt a file:"
echo "   sops --decrypt cluster/ts-router/traefik/.env.enc > cluster/ts-router/traefik/.env"
echo ""
echo "4. IMPORTANT: Backup your age key!"
echo "   cp $AGE_KEY_FILE somewhere-safe/"
echo ""
echo "=== Done ==="
