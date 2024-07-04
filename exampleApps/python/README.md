# Example python app

This Python app is intended to demonstrate how to connect to the MySQL Cluster via the MySQL Router, deployed from the template in Railway.

## Required environment variables

You should set the following variables in the service configuration in Railway

```MYSQL_ROUTER_HOST=${{mysql router.RAILWAY_PRIVATE_DOMAIN}}
MYSQL_ROUTER_PORT=6446
MYSQL_USER=${{mysql router.MYSQL_USER}}
MYSQL_PASSWORD=${{mysql router.MYSQL_PASSWORD}}
MYSQL_DB=railway```