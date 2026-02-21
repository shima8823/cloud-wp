#!/bin/bash

set -e

# Default to localhost if DOMAIN_NAME is not set
if [ -z "${DOMAIN_NAME}" ]; then
    export DOMAIN_NAME="localhost"
    echo "DOMAIN_NAME not set, using default: localhost"
fi

# Determine SSL certificate paths
LE_CERT="/etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem"
LE_KEY="/etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem"

if [ -f "$LE_CERT" ] && [ -f "$LE_KEY" ]; then
    echo "Using Let's Encrypt certificate for ${DOMAIN_NAME}"
    export SSL_CERTIFICATE="$LE_CERT"
    export SSL_CERTIFICATE_KEY="$LE_KEY"
else
    echo "Let's Encrypt certificate not found, using self-signed certificate..."
    SSL_DIR="/etc/nginx/ssl"
    CERT_FILE="${SSL_DIR}/${DOMAIN_NAME}.crt"
    KEY_FILE="${SSL_DIR}/${DOMAIN_NAME}.key"

    if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$KEY_FILE" \
            -out "$CERT_FILE" \
            -subj "/C=JP/ST=Tokyo/O=42Tokyo/OU=42/CN=${DOMAIN_NAME}"
        echo "Self-signed certificate generated successfully."
    fi

    export SSL_CERTIFICATE="$CERT_FILE"
    export SSL_CERTIFICATE_KEY="$KEY_FILE"
fi

# Generate nginx config from template
envsubst '${DOMAIN_NAME} ${SSL_CERTIFICATE} ${SSL_CERTIFICATE_KEY}' \
    < /etc/nginx/conf.d/default.conf.template \
    > /etc/nginx/conf.d/default.conf

echo "Starting nginx..."
exec nginx -g "daemon off;"
