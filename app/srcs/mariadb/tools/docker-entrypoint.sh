#!/bin/bash

set -e

# Environment variable validation
required_vars=("DB_NAME" "DB_USER" "DB_PASSWORD" "DB_ROOT_PASSWORD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable '$var' is not set." >&2
        exit 1
    fi
done

# Ensure directories exist with correct permissions
mkdir -p /var/log/mysql /run/mysqld
chown -R mysql:mysql /var/log/mysql /run/mysqld /var/lib/mysql

# Check if database needs initialization
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB..."

    # Initialize database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "Starting temporary MariaDB server..."
    # Start MariaDB temporarily without networking for setup
    mysqld --user=mysql --skip-networking &
    pid="$!"

    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB to start..."
    for i in {1..30}; do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if ! mysqladmin ping --silent 2>/dev/null; then
        echo "MariaDB failed to start"
        exit 1
    fi

    echo "Configuring MariaDB..."
    # Run initialization SQL
    mysql --user=root << EOF
        -- Set root password
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        -- Create database
        CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
        -- Create user
        CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        -- Grant privileges
        GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
        -- Remove anonymous users
        DELETE FROM mysql.user WHERE User='';
        -- Apply changes
        FLUSH PRIVILEGES;
EOF

    echo "Database configured successfully."

    # Shutdown temporary server
    mysqladmin --user=root --password="${DB_ROOT_PASSWORD}" shutdown

    echo "Temporary server stopped."
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql
