#!/usr/bin/env bash
# Secret Generator Script
# Generate various types of secure secrets

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << EOF
${BLUE}VPS Secret Generator${NC}

Usage: $0 [OPTIONS]

Options:
    -l, --length LENGTH       Secret length (default: 32)
    -t, --type TYPE          Secret type (password|key|uuid|pronounceable)
    -o, --output FILE        Output to file
    -n, --count COUNT        Number of secrets to generate (default: 1)
    -f, --format FORMAT      Output format (raw|json|env|yaml)
    -h, --help              Show this help

Secret Types:
    password    Alphanumeric with special chars (default)
    key         API key format (uppercase + numbers)
    uuid        UUID v4 format
    pronounceable  Easy to read words
    aws         AWS-style access key
    hmac        HMAC signing key
    jwt         JWT secret

Examples:
    $0                          # 32-char password
    $0 -l 64                    # 64-char password
    $0 -t uuid                  # UUID v4
    $0 -t key -l 40             # 40-char API key
    $0 -n 5 -o secrets.txt      # 5 passwords to file
    $0 -t jwt -l 64 -f json     # JWT secret as JSON
EOF
    exit 1
}

# Generate random string
generate_password() {
    local length=$1
    tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom | head -c "${length}"
}

# Generate API key style
generate_key() {
    local length=$1
    tr -dc 'A-Z0-9' < /dev/urandom | head -c "${length}"
}

# Generate UUID v4
generate_uuid() {
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    echo "$uuid"
}

# Generate pronounceable password
generate_pronounceable() {
    local words=$1
    local password=""
    
    local consonants="bcdfghjklmnpqrstvwxyz"
    local vowels="aeiou"
    
    for ((i=0; i<words; i++)); do
        # Consonant
        password+="${consonants:$((RANDOM % ${#consonants})):1}"
        # Vowel
        password+="${vowels:$((RANDOM % ${#vowels})):1}"
        # Consonant
        password+="${consonants:$((RANDOM % ${#consonants})):1}"
        # Add number
        password+="$((RANDOM % 10))"
        # Add separator
        [[ $i -lt $((words-1)) ]] && password+="-"
    done
    
    echo "$password"
}

# Generate AWS-style key
generate_aws_key() {
    local access_key=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 20)
    local secret_key=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 40)
    echo "AKIA${access_key}"
    echo "${secret_key}"
}

# Generate HMAC key
generate_hmac() {
    local length=$1
    openssl rand -hex $((length / 2)) | tr -d '\n'
}

# Generate JWT secret
generate_jwt() {
    local length=$1
    openssl rand -base64 $((length / 4 * 3)) | tr -d '\n' | tr '/+' '_-'
}

# Generate certificate
generate_certificate() {
    local type=$1
    shift
    local common_name=$1
    
    case "$type" in
        ca)
            openssl genrsa -out /tmp/ca.key 4096
            openssl req -new -x509 -days 3650 -key /tmp/ca.key \
                -subj "/CN=${common_name}" -out /tmp/ca.crt
            ;;
        server)
            local key_file="${common_name}.key"
            local cert_file="${common_name}.crt"
            
            openssl genrsa -out "$key_file" 4096
            openssl req -new -key "$key_file" \
                -subj "/CN=${common_name}" -out /tmp/server.csr
            openssl x509 -req -days 365 -in /tmp/server.csr \
                -CA /tmp/ca.crt -CAkey /tmp/ca.key -CAcreateserial \
                -out "$cert_file"
            ;;
        client)
            local key_file="${common_name}.key"
            local cert_file="${common_name}.crt"
            
            openssl genrsa -out "$key_file" 4096
            openssl req -new -key "$key_file" \
                -subj "/CN=${common_name}" -out /tmp/client.csr
            openssl x509 -req -days 365 -in /tmp/client.csr \
                -CA /tmp/ca.crt -CAkey /tmp/ca.key -CAcreateserial \
                -out "$cert_file"
            ;;
    esac
    
    rm -f /tmp/*.csr
}

# Parse arguments
LENGTH=32
TYPE="password"
OUTPUT=""
COUNT=1
FORMAT="raw"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--length) LENGTH="$2"; shift 2 ;;
        -t|--type) TYPE="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -n|--count) COUNT="$2"; shift 2 ;;
        -f|--format) FORMAT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Generate secrets
generate_secrets() {
    local result=""
    
    for ((i=0; i<COUNT; i++)); do
        case "$TYPE" in
            password)
                generate_password "$LENGTH"
                ;;
            key|api-key)
                generate_key "$LENGTH"
                ;;
            uuid)
                generate_uuid
                ;;
            pronounceable)
                generate_pronounceable 4
                ;;
            aws)
                generate_aws_key
                ;;
            hmac)
                generate_hmac "$LENGTH"
                ;;
            jwt)
                generate_jwt "$LENGTH"
                ;;
            *)
                echo -e "${RED}Unknown type: $TYPE${NC}" >&2
                exit 1
                ;;
        esac
    done
}

# Output result
output_result() {
    local secrets="$1"
    
    case "$FORMAT" in
        raw)
            echo "$secrets"
            ;;
        json)
            echo "{\"secret\": \"$secrets\", \"type\": \"$TYPE\", \"length\": $LENGTH}"
            ;;
        env)
            echo "SECRET_${TYPE^^}=$secrets"
            ;;
        yaml)
            echo "secret:"
            echo "  value: $secrets"
            echo "  type: $TYPE"
            echo "  length: $LENGTH"
            ;;
    esac
}

# Main
if [[ -n "$OUTPUT" ]]; then
    generate_secrets > "$OUTPUT"
    chmod 600 "$OUTPUT"
    echo -e "${GREEN}Secret saved to: $OUTPUT${NC}"
else
    output_result "$(generate_secrets)"
fi
