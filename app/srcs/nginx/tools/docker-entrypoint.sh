#!/bin/bash

set -e

# Environment variable validation
if [ -z "${DOMAIN_NAME}" ]; then
    echo "Error: Required environment variable 'DOMAIN_NAME' is not set." >&2
    exit 1
fi

# Generate SSL certificate if not exists
SSL_DIR="/etc/nginx/ssl"
CERT_FILE="${SSL_DIR}/${DOMAIN_NAME}.crt"
KEY_FILE="${SSL_DIR}/${DOMAIN_NAME}.key"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Generating SSL certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/C=JP/ST=Tokyo/O=42Tokyo/OU=42/CN=${DOMAIN_NAME}"
    echo "SSL certificate generated successfully."
fi

# Generate nginx config from template
envsubst '${DOMAIN_NAME}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "Starting nginx..."
exec nginx -g "daemon off;"
