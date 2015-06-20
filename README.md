Learning Docker http://docker.io/ by creating a pgpool cluster
==================

####Requirements
- docker that supports `exec` command ('exec' is available starting from docker version 1.3)

###Pgpool2 cluster + Postgresql Streaming Replication Test
To understand setup architecture, please take a look at:
- http://www.pgpool.net/pgpool-web/contrib_docs/watchdog/en.html
- http://www.pgpool.net/docs/pgpool-II-3.2.0/wd-en.html
- https://github.com/faja/howtos/blob/master/sql/postgresql/README.md

This simple scripts will help you to learn more about docker and pgpool clustering.

####Initial setup

1. To create environment run script `pgpool.sh`. It will launch 6 docker containers and prepare all the config files: 
 - the application (app) 
 [you can deploy any app in this container to access pgpool cluster]
 - master (postgresql) 
 - slave1 (postgresql)
 - slave2 (postgresql)
 - pgpool-1 (pgpool2 node)
 - pgpool-2 (pgpool2 node)
 
 If everything goes smoothhly, you will see similar message in the end:
``` 
* Starting pgpool-II pgpool
   ...done.
3
master 5432 1 0.000000
slave1 5432 1 0.500000
slave2 5432 3 0.500000
```

Later if you need to get information about pgpool status and its nodes roles, just run:
```
./sh_pool_nodes.sh

 node_id | hostname | port | status | lb_weight |  role
---------+----------+------+--------+-----------+---------
 0       | master   | 5432 | 3      | 0.000000  | primary
 1       | slave1   | 5432 | 2      | 0.500000  | standby
 2       | slave2   | 5432 | 2      | 0.500000  | standby
(3 rows)

```
This means that pool is up and functioning, and all the servers in pool are online. You can run docker ps and check what containers have been created:
```
CONTAINER ID        IMAGE                      COMMAND             CREATED             STATUS              PORTS                       NAMES
1014dee46ebc        postmart/psql-9.3:latest   "/bin/bash"         2 hours ago         Up 2 hours                                      pgpool-1
ba2edb256668        postmart/psql-9.3:latest   "/bin/bash"         2 hours ago         Up 2 hours                                      pgpool-2
ec397860af5a        postmart/psql-9.3:latest   "/bin/bash"         2 hours ago         Up 2 hours                                      app
3d5ad6d50d8f        postmart/psql-9.3:latest   "/bin/bash"         2 hours ago         Up 2 hours                                      slave2
c2fc3b670868        postmart/psql-9.3:latest   "/bin/bash"         2 hours ago         Up 2 hours                                      slave1
13cbdbc1d698        postmart/psql-9.3:latest   "/bin/bash"         2 hours ago         Up 2 hours                                      master

```

So we have 2 pgpool nodes to avoid SPOF. This means that our application container will access database using virtual IP. Check `delegate_ip` file to see default virtual IP. Change this IP to any you want.

### Tests:

    ./test.sh : # simulate failure of master db server and automatic failover
    ./test_recover_master.sh : # recover initial master in case it went down
    ./find_lags.sh # calculating streaming replication lags in seconds


#### Dockerfile
There is ruby installed in the docker image, as I am locally testing with rails app. Feel free to remove ruby from the image to free some space.

