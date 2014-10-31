#!/bin/bash

FALLING_NODE=$1
OLD_MASTER=$2
NEW_MASTER=$3
SLAVE1=`cat /etc/hosts|grep slave1 | cut -d ' ' -f1`
SLAVE2=`cat /etc/hosts|grep slave2 | cut -d ' ' -f1`
if [[ $FALLING_NODE -eq '0' ]]
then

ssh -T -i /var/lib/postgresql/.ssh/id_rsa postgres@$SLAVE1 touch /tmp/pgsql.trigger
ssh -T -i /var/lib/postgresql/.ssh/id_rsa postgres@$SLAVE1 "while test ! -f /var/lib/postgresql/9.3/main/recovery.done; do sleep 1; done; scp /var/lib/postgresql/9.3/main/pg_xlog/*history* postgres@$SLAVE2:/var/lib/postgresql/9.3/main/pg_xlog/"
ssh -T -i /var/lib/postgresql/.ssh/id_rsa postgres@$SLAVE2 "sed -i 's/master/slave1/' /var/lib/postgresql/9.3/main/recovery.conf"
ssh -T -i /var/lib/postgresql/.ssh/id_rsa postgres@$SLAVE2 /etc/init.d/postgresql restart
/usr/sbin/pcp_attach_node 10 localhost 9898 pgpool pgpool 2
fi
