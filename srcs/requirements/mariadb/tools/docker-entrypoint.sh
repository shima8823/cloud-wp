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

# Ensure log directory exists
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql

log_file="/var/log/mysql/setup.log"

if [ ! -d "/var/lib/mysql/mariadb" ]; then
    echo "Initializing MariaDB..." >> $log_file

    echo "Running as user: $(whoami)" >> $log_file

    mysql_install_db >> $log_file 2>&1
    if [ $? -eq 0 ]; then
        echo "Database installed successfully." >> $log_file
    else
        echo "Failed to install database." >> $log_file
    fi

    mysqld --bootstrap << EOF >> $log_file 2>&1
        ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
        CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
        CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
        GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
        DELETE FROM mysql.user WHERE User='';
        FLUSH PRIVILEGES;
EOF
    if [ $? -eq 0 ]; then
        echo "Database configured successfully." >> $log_file
    else
        echo "Failed to configure database." >> $log_file
    fi
fi

mysqld_safe >> $log_file 2>&1
