#!/bin/bash

# Replace placeholders in the my.cnf file with actual environment variable values
sed -i "s/@@SERVER_ID@@/$SERVER_ID/g" /etc/mysql/my.cnf
sed -i "s/@@HOSTNAME@@/$HOSTNAME/g" /etc/mysql/my.cnf


echo "Checking the data directory"

# Ensure the data directory is initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MySQL data directory..."
    mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
fi

# Start MySQL server
docker-entrypoint.sh mysqld
