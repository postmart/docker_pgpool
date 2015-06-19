#!/bin/bash

VOLUME=$PWD/keys:/keys
#IP=$(/sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
pg_data_dir=/var/lib/postgresql/9.3/main
DELEGATE_IP=$(cat delegate_ip)
MASTER_IP=""
SLAVE1_IP=""
SLAVE2_IP=""
PGPOOL1_IP=""
PGPOOL2_IP=""
APP_IP=""
nodes=$(cat nodes)
echo -e "\e[32mChecking docker version"
MIN_VER=1.3
VER=$(docker -v | awk '{print $3}' | cut -d, -f1 |cut -d. -f1,2)
if [[ 1 -eq `echo "${VER} < ${MIN_VER}" | bc ` ]] ; then
    echo -e "\e[31mYour docker version is lower than $MIN_VER"
    echo -e "\e[32mCurrent docker version: "$VER
    echo -e "\e[32mPlease upgrade your docker before running this script"
    echo -e "\e[34mExiting"
    echo -e "\e[0m"
    exit 0
else
   echo -e "\e[32mYou docker version is OK"
fi


# check whether docker image is already available
echo -e "\e[32mCheck whether docker image locally available"
echo -e "\e[0m"
if ! docker images | grep postmart/psql-9.3 ; then
    echo "Image is not available, need to pull first"
    docker pull postmart/psql-9.3:latest
        if [[ $? == 0 ]]; then
            for dir in ${nodes[*]}; do
            mkdir -p keys/$dir
            done
        else
            print -e "\e[33Something went wrong"
            exit 1
        fi
fi

# installing postgresql server on all machines, and generate ssh keys
echo -e "\e[32mstarting docker containers"
echo -e "\e[0m"
for node in ${nodes[*]}; do
docker run --name $node --hostname=$node --privileged=true -t -v $VOLUME postmart/psql-9.3:latest & 
st=`echo $?`
#echo "Status: "$st
  if [[ $st != 0 ]]; then
    echo "Error staring containers"
    exit 1
  fi

done

sleep 2

while [[ -z "$MASTER_IP" ]] || [[  -z "$SLAVE1_IP" ]] || [[ -z "$SLAVE2_IP" ]] || [[ -z "$PGPOOL1_IP" ]] || [[ -z "$PGPOOL2_IP" ]] || [[ -z "$APP_IP" ]] ; do
MASTER_IP=$(docker inspect master | grep IPAddress | awk '{print $2}' | tr -d '",\n')
echo ""
echo "master: " $MASTER_IP
SLAVE1_IP=$(docker inspect slave1 | grep IPAddress | awk '{print $2}' | tr -d '",\n')
echo "slave1: " $SLAVE1_IP
SLAVE2_IP=$(docker inspect slave2 | grep IPAddress | awk '{print $2}' | tr -d '",\n')
echo "slave2: " $SLAVE2_IP
PGPOOL1_IP=$(docker inspect pgpool-1 | grep IPAddress | awk '{print $2}' | tr -d '",\n')
echo "pgpool-1: " $PGPOOL1_IP
PGPOOL2_IP=$(docker inspect pgpool-2 | grep IPAddress | awk '{print $2}' | tr -d '",\n')
echo "pgpool-2: " $PGPOOL2_IP
APP_IP=$(docker inspect app | grep IPAddress | awk '{print $2}' | tr -d '",\n')

done

echo "................................"
echo -e "\e[0m"
echo "................................"
echo "................................"
echo -e "\e[32mStarting ssh"
echo -e "\e[0m"
docker exec master /etc/init.d/ssh start
docker exec pgpool-2 /etc/init.d/ssh start
docker exec slave1 /etc/init.d/ssh start
docker exec slave2 /etc/init.d/ssh start
docker exec pgpool-1 /etc/init.d/ssh start
echo "................................"
echo -e "\e[95mStopping psql"
echo -e "\e[0m"
docker exec master /etc/init.d/postgresql stop
docker exec slave1 /etc/init.d/postgresql stop
docker exec slave2 /etc/init.d/postgresql stop

echo -e "\e[32mGenerating ssh keys"
echo -e "\e[0m"

for node in ${nodes[*]}; do
docker exec $node bash -c "mkdir -p /keys/$node";
docker exec $node bash -c "ssh-keygen  -b 2048 -t rsa -f /keys/$node/id_rsa -q " ;
docker exec $node bash -c "mkdir /root/.ssh/" ;
docker exec $node bash -c "cp /keys/$node/id_rsa /root/.ssh/"
docker exec $node bash -c "mkdir -p /var/lib/postgresql/.ssh/" ; 
done

for node in ${nodes[*]}; do
docker exec $node bash -c "cd /keys/ && find . -type f -name id_rsa.pub -exec cat {} \; >> /root/.ssh/authorized_keys \
>> /var/lib/postgresql/.ssh/authorized_keys"
done

echo "................................"
sleep 0.5
echo -e "\e[32mAdding entries to /etc/hosts"
echo -e "\e[0m"
echo -e "\e[95m:::::for master"
docker exec master bash -c "echo $SLAVE1_IP slave1 >> /etc/hosts"
docker exec master bash -c "echo $SLAVE2_IP slave2 >> /etc/hosts"
docker exec master bash -c "echo $PGPOOL2_IP pgpool-2 >> /etc/hosts"
docker exec master bash -c "echo $PGPOOL1_IP pgpool-1 >> /etc/hosts"
docker exec master bash -c "echo $APP_IP app >> /etc/hosts"
sleep 0.5
echo -e "\e[95m:::::for slave1"
docker exec slave1 bash -c "echo $SLAVE2_IP slave2 >> /etc/hosts"
docker exec slave1 bash -c "echo $MASTER_IP master >> /etc/hosts"
docker exec slave1 bash -c "echo $PGPOOL2_IP pgpool-2 >> /etc/hosts"
docker exec slave1 bash -c "echo $PGPOOL1_IP pgpool-1 >> /etc/hosts"
docker exec slave1 bash -c "echo $APP_IP app >> /etc/hosts"
sleep 0.5
echo -e "\e[95m:::::for slave2"
docker exec slave2 bash -c "echo $MASTER_IP master >> /etc/hosts"
docker exec slave2 bash -c "echo $SLAVE1_IP slave1 >> /etc/hosts"
docker exec slave2 bash -c "echo $PGPOOL2_IP pgpool-2 >> /etc/hosts"
docker exec slave2 bash -c "echo $PGPOOL1_IP pgpool-1 >> /etc/hosts"
docker exec slave2 bash -c "echo $APP_IP app >> /etc/hosts"
sleep 0.5

echo -e "\e[95m:::::for pgpool-2"
docker exec pgpool-2 bash -c "echo $MASTER_IP master >> /etc/hosts"
docker exec pgpool-2 bash -c "echo $SLAVE1_IP slave1 >> /etc/hosts"
docker exec pgpool-2 bash -c "echo $SLAVE2_IP slave2 >> /etc/hosts"
docker exec pgpool-2 bash -c "echo $PGPOOL1_IP pgpool-1 >> /etc/hosts"
docker exec pgpool-2 bash -c "echo $APP_IP app >> /etc/hosts"
sleep 0.5

echo -e "\e[95m:::::for pgpool-1"
docker exec pgpool-1 bash -c "echo $MASTER_IP master >> /etc/hosts"
docker exec pgpool-1 bash -c "echo $SLAVE1_IP slave1 >> /etc/hosts"
docker exec pgpool-1 bash -c "echo $PGPOOL2_IP pgpool-2 >> /etc/hosts"
docker exec pgpool-1 bash -c "echo $SLAVE2_IP slave2 >> /etc/hosts"
docker exec pgpool-1 bash -c "echo $APP_IP app >> /etc/hosts"

echo -e "\e[95m:::::for app"
docker exec app bash -c "echo $MASTER_IP master >> /etc/hosts"
docker exec app bash -c "echo $SLAVE1_IP slave1 >> /etc/hosts"
docker exec app bash -c "echo $PGPOOL2_IP pgpool-2 >> /etc/hosts"
docker exec app bash -c "echo $SLAVE2_IP slave2 >> /etc/hosts"

echo "................................"
echo -e "\e[32mtesting ssh"
for node in ${nodes[*]}; do
    echo -e "\e[95m:::::::::::on $node"
    docker exec $node bash -c 'file=/keys/nodes ; for name in `cat $file`; do ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@$name ; done'
done

echo "Copy known_hosts to postgres dir"
for node in ${nodes[*]}; do
    docker exec $node bash -c "cp /root/.ssh/known_hosts /var/lib/postgresql/.ssh/" ;
done

echo -e "\e[32mCopy postgres config file"
echo -e "\e[0m"
docker exec master cp /keys/master_postgresql.conf /etc/postgresql/9.3/main/postgresql.conf
docker exec slave1 cp /keys/slave_postgresql.conf /etc/postgresql/9.3/main/postgresql.conf
docker exec slave2 cp /keys/slave_postgresql.conf /etc/postgresql/9.3/main/postgresql.conf

echo -e "\e[32mAdding hosts for replication in pg_hba.conf"
echo -e "\e[95m:::::::::on master"
echo -e "\e[0m"
docker exec master bash -c "echo host replication repl $SLAVE1_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec master bash -c "echo host replication repl $SLAVE2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec master bash -c "echo host all pgpool $PGPOOL2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec master bash -c "echo host all all $PGPOOL2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec master bash -c "echo host all all $PGPOOL1_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"

echo -e "\e[95m:::::::::on slave1"
echo -e "\e[0m"
docker exec slave1 bash -c "echo host replication repl $MASTER_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec slave1 bash -c "echo host replication repl $SLAVE2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec slave1 bash -c "echo host all pgpool $PGPOOL2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec slave1 bash -c "echo host all all $PGPOOL2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec slave1 bash -c "echo host all all $PGPOOL1_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"

echo -e "\e[95m:::::::::on slave2"
echo -e "\e[0m"
docker exec slave2 bash -c "echo host replication repl $MASTER_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec slave2 bash -c "echo host replication repl $SLAVE1_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec slave2 bash -c "echo host all pgpool $PGPOOL2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec slave2 bash -c "echo host all all $PGPOOL2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec slave2 bash -c "echo host all all $PGPOOL1_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"

docker exec pgpool-2 bash -c "echo host all all $MASTER_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-2 bash -c "echo host all all $SLAVE1_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-2 bash -c "echo host all all $SLAVE2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-2 bash -c "echo host all all $PGPOOL1_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-2 bash -c "echo host all all $APP_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"

docker exec pgpool-1 bash -c "echo host all all $MASTER_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-1 bash -c "echo host all all $SLAVE1_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-1 bash -c "echo host all all $SLAVE2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-1 bash -c "echo host all all $PGPOOL2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-1 bash -c "echo host all all $APP_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"

#echo -e "\e[95mcreating user database on master"
#echo -e "\e[0m"
docker exec master /etc/init.d/postgresql start
#docker exec slave1 /etc/init.d/postgresql start
#docker exec slave2 /etc/init.d/postgresql start
#docker exec master bash -c "sudo -u postgres psql --file=/keys/create_user_master.sql "

echo -e "\e[32mCreating base backup  on master"
echo -e "\e[0m"
docker exec master bash -c "/keys/base_backup_master.sh"

echo -e "\e[32mCopy base_backup.tar to slaves"
echo -e "\e[0m"
docker exec master bash -c "scp /var/lib/postgresql/9.3/base_backup.tar postgres@slave1:~"
docker exec master bash -c "scp /var/lib/postgresql/9.3/base_backup.tar postgres@slave2:~"

echo -e "\e[32mSlave1 Replication"
echo -e "\e[0m"
docker exec slave1 bash -c "/keys/slave1_replication.sh"
echo -e "\e[32mSlave2 Replication"
echo -e "\e[0m"
docker exec slave2 bash -c "/keys/slave2_replication.sh"

echo -e "\e[32mInstalling pgpool to pgpool-2"
echo -e "\e[0m"
docker exec pgpool-2 apt-get install -q -y  pgpool2 postgresql-9.3-pgpool2 arping
docker exec pgpool-1 apt-get install -q -y  pgpool2 postgresql-9.3-pgpool2 arping
docker exec pgpool-2 /etc/init.d/pgpool2 stop
docker exec pgpool-1 /etc/init.d/pgpool2 stop
docker exec pgpool-2 bash -c "/keys/pgpool-2_pgpool.sh"
docker exec pgpool-2 bash -c "mkdir -p /var/lib/postgresql/bin"
docker exec pgpool-2 bash -c "cp /keys/pgpool-2_failover.sh /var/lib/postgresql/bin/failover.sh"

docker exec pgpool-1 bash -c "/keys/pgpool-1_pgpool.sh"
docker exec pgpool-1 bash -c "mkdir -p /var/lib/postgresql/bin"
docker exec pgpool-1 bash -c "cp /keys/pgpool-2_failover.sh /var/lib/postgresql/bin/failover.sh"

sleep 1
docker exec master bash -c "cp /keys/pgpool-recovery.so /usr/lib/postgresql/9.3/lib/pgpool-recovery.so"
docker exec slave1 bash -c "cp /keys/pgpool-recovery.so /usr/lib/postgresql/9.3/lib/pgpool-recovery.so"
docker exec slave2 bash -c "cp /keys/pgpool-recovery.so /usr/lib/postgresql/9.3/lib/pgpool-recovery.so"

docker exec master bash -c "cp /keys/basebackup.sh $pg_data_dir/basebackup.sh"
docker exec slave1 bash -c "cp /keys/basebackup.sh $pg_data_dir/basebackup.sh"
docker exec slave2 bash -c "cp /keys/basebackup.sh $pg_data_dir/basebackup.sh"

docker exec master bash -c "cp /keys/pgpool_remote_start $pg_data_dir/pgpool_remote_start"
docker exec slave1 bash -c "cp /keys/pgpool_remote_start $pg_data_dir/pgpool_remote_start"
docker exec slave2 bash -c "cp /keys/pgpool_remote_start $pg_data_dir/pgpool_remote_start"

docker exec master bash -c "cp /keys/pgpool-recovery $pg_data_dir/pgpool-recovery"
docker exec slave1 bash -c "cp /keys/pgpool-recovery $pg_data_dir/pgpool-recovery"
docker exec slave2 bash -c "cp /keys/pgpool-recovery $pg_data_dir/pgpool-recovery"

echo -e "\e[32mStarting pool on pgpool-2"
echo -e "\e[0m"

docker exec pgpool-2 bash -c "/keys/pgpool-2_start.sh"
sleep 3
docker exec pgpool-1 bash -c "/keys/pgpool-2_start.sh"

echo -e "\e[32mExecute psql -f pgpool-recovery.sql template1"
echo -e "\e[0m"
docker exec pgpool-2 bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -f /keys/pgpool-recovery.sql template1"
echo "................................"
