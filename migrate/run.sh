#!/bin/bash

set -e

# Generate the dump file paths using the DATABASE_NAME environment variable and current date
DATABASE_NAME="${DATABASE_NAME}"
DUMP_FILE="/tmp/${DATABASE_NAME}_$(date +%F).sql"
COMPRESSED_DUMP_FILE="${DUMP_FILE}.gz"

# Create a dump of the database and compress it
echo "Creating and compressing MySQL dump..."
mysqldump -u $SOURCE_MYSQL_USER -p$SOURCE_MYSQL_PASSWORD -h $SOURCE_MYSQL_HOST --databases $DATABASE_NAME --routines --triggers --events | gzip > $COMPRESSED_DUMP_FILE

echo "Dump created and compressed as $COMPRESSED_DUMP_FILE"

# Function to stop group replication
stop_group_replication() {
    mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $1 -e "STOP GROUP_REPLICATION;"
}

# Function to reset slave configuration
reset_slave() {
    mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $1 -e "RESET MASTER;"
    mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $1 -e "RESET SLAVE ALL;"
}

# Function to purge GTIDs
purge_gtids() {
    GTID_EXECUTED=$(mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $PRIMARY_HOST -e "SHOW GLOBAL VARIABLES LIKE 'gtid_executed';" | grep -o '^[^ ]*')
    mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $1 -e "SET GLOBAL gtid_purged = '$GTID_EXECUTED';"
}

# Function to start group replication
start_group_replication() {
    mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $1 -e "START GROUP_REPLICATION;"
}

# Decompress the dump file
gunzip < $COMPRESSED_DUMP_FILE > $DUMP_FILE

# Stop group replication on all nodes
echo "Stopping group replication on all nodes..."
stop_group_replication $PRIMARY_HOST
stop_group_replication $SECONDARY_HOST1
stop_group_replication $SECONDARY_HOST2

# Ensure the primary node is writable
echo "Ensuring the primary node is writable..."
mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $PRIMARY_HOST -e "SET GLOBAL super_read_only = OFF;"

# Restore the dump to the primary node
echo "Restoring the dump to the primary node..."
mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $PRIMARY_HOST < $DUMP_FILE

# Start group replication on the primary node to continue receiving new writes
echo "Starting group replication on the primary node..."
start_group_replication $PRIMARY_HOST

# Reset slave configuration and purge GTIDs on secondary nodes
echo "Resynchronizing secondary nodes..."
reset_slave $SECONDARY_HOST1
purge_gtids $SECONDARY_HOST1
start_group_replication $SECONDARY_HOST1

reset_slave $SECONDARY_HOST2
purge_gtids $SECONDARY_HOST2
start_group_replication $SECONDARY_HOST2

# Check cluster status on all nodes
echo "Checking cluster status..."
mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $PRIMARY_HOST -e "SHOW STATUS LIKE 'group_replication%';"
mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $SECONDARY_HOST1 -e "SHOW STATUS LIKE 'group_replication%';"
mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $SECONDARY_HOST2 -e "SHOW STATUS LIKE 'group_replication%';"

mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $PRIMARY_HOST -e "SELECT * FROM performance_schema.replication_group_members;"
mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $SECONDARY_HOST1 -e "SELECT * FROM performance_schema.replication_group_members;"
mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $SECONDARY_HOST2 -e "SELECT * FROM performance_schema.replication_group_members;"

# Push the dump file to MinIO
echo "Pushing the dump file to MinIO..."
mc alias set myminio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY
mc cp $COMPRESSED_DUMP_FILE myminio/$MINIO_BUCKET/

echo "Database restored and replication restarted on all nodes."
echo "Dump file pushed to MinIO."
