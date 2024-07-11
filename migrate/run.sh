#!/bin/bash

set -e

# Generate the dump file paths using the DATABASE_NAME environment variable and current date
DATABASE_NAME="${DATABASE_NAME}"
TIMESTAMP=$(date +%F_%H-%M-%S)
DUMP_FILE="/tmp/${DATABASE_NAME}_${TIMESTAMP}.sql"
COMPRESSED_DUMP_FILE="${DUMP_FILE}.gz"

# Create a dump of the database and compress it
echo "Creating and compressing MySQL dump..."
mysqldump --set-gtid-purged=OFF -u $SOURCE_MYSQL_USER -p$SOURCE_MYSQL_PASSWORD -h $SOURCE_MYSQL_HOST --databases $DATABASE_NAME --routines --triggers --events | gzip > $COMPRESSED_DUMP_FILE

echo "Dump created and compressed as $COMPRESSED_DUMP_FILE"

# Decompress the dump file
gunzip < $COMPRESSED_DUMP_FILE > $DUMP_FILE

# Restore the dump to the primary node
echo "Restoring the dump to the primary node..."
mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $TARGET_MYSQL_HOST -P $TARGET_MYSQL_PORT < $DUMP_FILE

# Check cluster status on all nodes
echo "Checking cluster status..."
mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASSWORD -h $TARGET_MYSQL_HOST -P $TARGET_MYSQL_PORT -e "SHOW STATUS LIKE 'group_replication%';"

# Push the dump file to MinIO
echo "Pushing the dump file to MinIO..."
mc alias set myminio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY
mc cp $COMPRESSED_DUMP_FILE myminio/$MINIO_BUCKET/

echo "Database restored and replication restarted on all nodes."
echo "Dump file pushed to MinIO."

# Delete the dump file after backup
echo "Deleting the dump files..."
rm -f $DUMP_FILE $COMPRESSED_DUMP_FILE

echo "Dump files deleted."