#!/bin/bash

# Wait for MySQL to be ready
wait_for_mysql() {
    while ! mysqladmin ping -h"$1" --silent; do
        sleep 1
    done
}

# Wait for MySQL instances to be ready
wait_for_mysql "$MYSQL1_HOST_NAME"
wait_for_mysql "$MYSQL2_HOST_NAME"
wait_for_mysql "$MYSQL3_HOST_NAME"

# Replace the placeholders in the JavaScript file with the env values
sed -e "s/@@MYSQL_ROOT_PASSWORD@@/$MYSQL_ROOT_PASSWORD/g" \
    -e "s/@@MYSQL1_HOST_NAME@@/$MYSQL1_HOST_NAME/g" \
    -e "s/@@MYSQL2_HOST_NAME@@/$MYSQL2_HOST_NAME/g" \
    -e "s/@@MYSQL3_HOST_NAME@@/$MYSQL3_HOST_NAME/g" \
    /initCluster.js > /tmp/initCluster.js

# Run the init script
mysqlsh root@"$MYSQL1_HOST_NAME":3306 --password=$MYSQL_ROOT_PASSWORD --file=/tmp/initCluster.js

# Remove this service
echo "Executing GraphQL mutation to remove the init service..."
response=$(curl --silent --location "$RAILWAY_API_URL" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $RAILWAY_API_TOKEN" \
  --data "{\"query\":\"mutation serviceDelete(\$environmentId: String, \$id: String!) { serviceDelete(environmentId: \$environmentId, id: \$id) }\",\"variables\":{\"environmentId\":\"$ENVIRONMENT_ID\",\"id\":\"$SERVICE_ID\"}}")

# Check for errors in the GraphQL response
if echo "$response" | grep -q '"errors"'; then
  echo "Failed to delete the service via the API. Response: $response"
  exit 1
else
  echo "GraphQL mutation executed successfully. Response: $response"
fi

# Exit after setup is complete
exit 0
