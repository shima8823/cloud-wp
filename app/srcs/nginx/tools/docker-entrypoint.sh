#!/bin/bash

set -e

# Default to localhost if DOMAIN_NAME is not set
if [ -z "${DOMAIN_NAME}" ]; then
    export DOMAIN_NAME="localhost"
    echo "DOMAIN_NAME not set, using default: localhost"
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
