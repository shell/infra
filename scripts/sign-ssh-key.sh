#!/bin/bash
# Sign an SSH public key with the CA
set -e

# Set SOPS age key location if not already set
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CA_DIR="$REPO_DIR/ansible/ssh-ca"

usage() {
    echo "Usage: $0 <public_key_path> <principal>"
    echo ""
    echo "Arguments:"
    echo "  public_key_path  Path to the SSH public key to sign (e.g., ~/.ssh/id_ed25519.pub)"
    echo "  principal        Username(s) the certificate can authenticate as (e.g., vlad)"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -V, --validity   Certificate validity period (default: +52w = 1 year)"
    echo ""
    echo "Examples:"
    echo "  $0 ~/.ssh/id_ed25519.pub vlad"
    echo "  $0 -V +4w ~/.ssh/id_ed25519.pub vlad    # 4 weeks validity"
    echo "  $0 ~/.ssh/id_ed25519.pub vlad,root      # Multiple principals"
    exit 1
}

# Default validity: 1 year (52 weeks)
VALIDITY="+52w"

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -V|--validity)
            VALIDITY="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Check arguments
if [ $# -lt 2 ]; then
    usage
fi

PUB_KEY_PATH="$1"
PRINCIPAL="$2"

# Expand ~ in path
PUB_KEY_PATH="${PUB_KEY_PATH/#\~/$HOME}"

# Validate public key exists
if [ ! -f "$PUB_KEY_PATH" ]; then
    echo "ERROR: Public key not found: $PUB_KEY_PATH"
    exit 1
fi

# Check CA exists
if [ ! -f "$CA_DIR/ca_key.enc" ]; then
    echo "ERROR: CA key not found at $CA_DIR/ca_key.enc"
    echo "Run setup-ssh-ca.sh first to create the CA"
    exit 1
fi

# Check for required tools
if ! command -v sops &> /dev/null; then
    echo "ERROR: sops is not installed."
    echo "Install with: brew install sops"
    exit 1
fi

echo "=== SSH Key Signing ==="
echo ""
echo "Public key: $PUB_KEY_PATH"
echo "Principal:  $PRINCIPAL"
echo "Validity:   $VALIDITY"
echo ""

# Decrypt CA private key temporarily
TEMP_CA_KEY=$(mktemp)
trap "rm -f $TEMP_CA_KEY" EXIT

echo "Decrypting CA private key..."
sops --decrypt "$CA_DIR/ca_key.enc" > "$TEMP_CA_KEY"
chmod 600 "$TEMP_CA_KEY"

# Calculate certificate path (same dir as public key, with -cert.pub suffix)
CERT_PATH="${PUB_KEY_PATH%.pub}-cert.pub"

# Sign the key
echo "Signing key..."
ssh-keygen -s "$TEMP_CA_KEY" \
    -I "$(whoami)@$(hostname)-$(date +%Y%m%d)" \
    -n "$PRINCIPAL" \
    -V "$VALIDITY" \
    "$PUB_KEY_PATH"

echo ""
echo "=== Certificate Created ==="
echo "Certificate: $CERT_PATH"
echo ""

# Show certificate details
echo "=== Certificate Details ==="
ssh-keygen -L -f "$CERT_PATH"
echo ""

echo "=== Usage ==="
echo ""
echo "SSH will automatically use the certificate when connecting."
echo "Test with: ssh -v $PRINCIPAL@<host>"
echo ""
echo "Look for 'Offering public key... certificate' in verbose output."
echo ""
