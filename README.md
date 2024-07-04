# MySQL InnoDB Cluster with MySQL Router

This repo contains the resources to deploy a MySQL InnoDB Cluster to [Railway](https://railway.app/).

To deploy your own MySQL cluster in Railway, just click the button below!

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/LjyGLg)

### About the MySQL Nodes

[/nodes](/nodes)

The MySQL nodes deployed in the cluster are built from the [official MySQL image in Docker](https://hub.docker.com/_/mysql).

The only customization to the image, is the inclusion of a [my.cnf file](/nodes/my.cnf) which configures the nodes as necessary to create the cluster.

### About the Init Service

[/initService](/initService)

The init service is used to execute the required commands against MySQL to create the cluster and join the members.  

Upon completion, it deletes itself via the Railway public API.

### Example Apps

[/exampleApps](/exampleApps/)

Included in this repo are example apps to demonstrate how to connect a client to the cluster via the [MySQL router](https://dev.mysql.com/doc/mysql-router/8.4/en/).
- [Python app](/exampleApps/python/)

## More Resources

There are many ways to configure a MySQL Cluster.  You should become familiar with the MySQL resources:
- [MySQL InnoDB Cluster Docs](https://dev.mysql.com/doc/mysql-shell/8.4/en/mysql-innodb-cluster.html)
- [MySQL Router Docs](https://dev.mysql.com/doc/mysql-router/8.4/en/)

## Contributions

Pull requests are welcome.  If you have any suggestions for how to improve this implementation of a MySQL InnoDB Cluster, please feel free to make the changes in a PR.