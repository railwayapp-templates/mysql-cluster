#!/bin/bash

# Set a default value for CLUSTER_NAME if it is not set
CLUSTER_NAME=${CLUSTER_NAME:-railwayCluster}

# Wait for MySQL to be ready
wait_for_mysql() {
    while ! mysqladmin ping -h"$1" --silent; do
        sleep 1
    done
}

# restart service function
restart_service() {
    local environment_id="$1"
    local service_id="$2"
    local api_token="$API_TOKEN"

    curl -X POST "https://backboard.railway.app/graphql/v2" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_token" \
        -d "{\"query\":\"mutation serviceInstanceRedeploy(\$environmentId: String!, \$serviceId: String!) { serviceInstanceRedeploy(environmentId: \$environmentId, serviceId: \$serviceId) }\",\"variables\":{\"environmentId\":\"$environment_id\",\"serviceId\":\"$service_id\"}}"
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
    -e "s/@@CLUSTER_NAME@@/$CLUSTER_NAME/g" \
    /initCluster.js > /tmp/initCluster.js

# Run the init script
mysqlsh root@"$MYSQL1_HOST_NAME":3306 --password=$MYSQL_ROOT_PASSWORD --file=/tmp/initCluster.js

# Restart the router service
echo "Executing GraphQL mutation to restart the router service..."
restart_service "$ENVIRONMENT_ID" "$ROUTER_SERVICE_ID"

exit 0
