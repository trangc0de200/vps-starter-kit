#!/usr/bin/env bash
# Encrypt Secrets Script
# Encrypt secrets using AES-256 or GPG

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="${SCRIPT_DIR}/../keys"

usage() {
    cat << EOF
${BLUE}VPS Secrets Encryption${NC}

Usage: $0 [OPTIONS]

Options:
    -i, --input FILE        Input file (required)
    -o, --output FILE      Output file (required)
    -m, --method METHOD    Encryption method (aes|gpg|sops)
    -p, --password         Use password encryption
    -k, --keyfile FILE     Use key file encryption
    -e, --encrypt          Encrypt mode (default)
    -d, --decrypt          Decrypt mode
    -h, --help            Show this help

Methods:
    aes    AES-256-CBC with PBKDF2 (default)
    gpg    GPG symmetric encryption
    sops   Mozilla SOPS (requires gcpkms/awskms/age)

Examples:
    # Encrypt with password
    $0 -i secrets.txt -o secrets.enc -p

    # Encrypt with key file
    $0 -i secrets.txt -o secrets.enc -k mykey.pem

    # Decrypt with password
    $0 -i secrets.enc -o secrets.txt -p -d

    # Encrypt with SOPS
    $0 -i secrets.yaml -o secrets.enc.yaml -m sops
EOF
    exit 1
}

# Check dependencies
check_deps() {
    local method=$1
    case "$method" in
        aes)
            command -v openssl >/dev/null || { echo "openssl required"; exit 1; }
            ;;
        gpg)
            command -v gpg >/dev/null || { echo "gpg required"; exit 1; }
            ;;
        sops)
            command -v sops >/dev/null || { echo "sops required (pip install sops)"; exit 1; }
            ;;
    esac
}

# Encrypt with AES
encrypt_aes() {
    local input=$1
    local output=$2
    local keyfile=$3
    
    if [[ -n "$keyfile" && -f "$keyfile" ]]; then
        # Use key file
        openssl enc -aes-256-cbc -salt -pbkdf2 \
            -in "$input" \
            -out "$output" \
            -pass file:"$keyfile"
    else
        # Use password
        echo -n "Enter encryption password: "
        read -s password
        echo
        openssl enc -aes-256-cbc -salt -pbkdf2 \
            -in "$input" \
            -out "$output" \
            -pass pass:"$password"
    fi
    
    echo -e "${GREEN}Encrypted: $output${NC}"
}

# Decrypt with AES
decrypt_aes() {
    local input=$1
    local output=$2
    local keyfile=$3
    
    if [[ -n "$keyfile" && -f "$keyfile" ]]; then
        openssl enc -aes-256-cbc -d -pbkdf2 \
            -in "$input" \
            -out "$output" \
            -pass file:"$keyfile"
    else
        echo -n "Enter decryption password: "
        read -s password
        echo
        openssl enc -aes-256-cbc -d -pbkdf2 \
            -in "$input" \
            -out "$output" \
            -pass pass:"$password"
    fi
    
    echo -e "${GREEN}Decrypted: $output${NC}"
}

# Encrypt with GPG
encrypt_gpg() {
    local input=$1
    local output=$2
    
    gpg --symmetric --cipher-algo AES256 --compress-algo zlib \
        --output "$output" "$input"
    
    echo -e "${GREEN}Encrypted with GPG: $output${NC}"
}

# Decrypt with GPG
decrypt_gpg() {
    local input=$1
    local output=$2
    
    gpg --decrypt --output "$output" "$input"
    
    echo -e "${GREEN}Decrypted: $output${NC}"
}

# Encrypt with SOPS
encrypt_sops() {
    local input=$1
    local output=$2
    
    sops --encrypt "$input" > "$output"
    
    echo -e "${GREEN}Encrypted with SOPS: $output${NC}"
}

# Parse arguments
INPUT=""
OUTPUT=""
METHOD="aes"
PASSWORD=false
KEYFILE=""
DECRYPT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input) INPUT="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -m|--method) METHOD="$2"; shift 2 ;;
        -p|--password) PASSWORD=true; shift ;;
        -k|--keyfile) KEYFILE="$2"; shift 2 ;;
        -e|--encrypt) DECRYPT=false; shift ;;
        -d|--decrypt) DECRYPT=true; shift ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Validate
if [[ -z "$INPUT" ]] || [[ -z "$OUTPUT" ]]; then
    echo -e "${RED}Input and output files required${NC}"
    usage
fi

if [[ ! -f "$INPUT" ]]; then
    echo -e "${RED}Input file not found: $INPUT${NC}"
    exit 1
fi

check_deps "$METHOD"

# Create key directory
mkdir -p "$KEY_DIR"

# Execute
case "$METHOD" in
    aes)
        if [[ "$DECRYPT" == "true" ]]; then
            decrypt_aes "$INPUT" "$OUTPUT" "$KEYFILE"
        else
            encrypt_aes "$INPUT" "$OUTPUT" "$KEYFILE"
        fi
        ;;
    gpg)
        if [[ "$DECRYPT" == "true" ]]; then
            decrypt_gpg "$INPUT" "$OUTPUT"
        else
            encrypt_gpg "$INPUT" "$OUTPUT"
        fi
        ;;
    sops)
        if [[ "$DECRYPT" == "true" ]]; then
            sops --decrypt "$INPUT" > "$OUTPUT"
        else
            encrypt_sops "$INPUT" "$OUTPUT"
        fi
        ;;
    *)
        echo -e "${RED}Unknown method: $METHOD${NC}"
        exit 1
        ;;
esac
