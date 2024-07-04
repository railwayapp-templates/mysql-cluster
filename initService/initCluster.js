var dbPassword = "@@MYSQL_ROOT_PASSWORD@@";
var mysql1Host = "@@MYSQL1_HOST_NAME@@";
var mysql2Host = "@@MYSQL2_HOST_NAME@@";
var mysql3Host = "@@MYSQL3_HOST_NAME@@";

dba.configureInstance({user: 'root', host: mysql1Host, password: dbPassword});
dba.configureInstance({user: 'root', host: mysql2Host, password: dbPassword});
dba.configureInstance({user: 'root', host: mysql3Host, password: dbPassword});

var cluster = dba.createCluster('testCluster');
cluster.addInstance({user: 'root', host: mysql2Host, password: dbPassword}, {recoveryMethod: 'clone'});
cluster.addInstance({user: 'root', host: mysql3Host, password: dbPassword}, {recoveryMethod: 'clone'});
print(cluster.status());
