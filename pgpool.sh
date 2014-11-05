VOLUME=$PWD/keys:/keys
IP=$(/sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
pg_data_dir=/var/lib/postgresql/9.3/main
nodes=(master slave1 slave2 pgpool-1 pgpool-2)
DELEGATE_IP=$(cat delegate_ip)
MASTER_IP=""
SLAVE1_IP=""
SLAVE2_IP=""
PGPOOL1_IP=""
PGPOOL2_IP=""
MERLIN_IP=""

for dir in ${nodes[*]}; do
mkdir -p keys/$dir
done

# installing postgresql server on all machines, and generate ssh keys
echo -e "\e[32mstarting docker containers"
echo -e "\e[0m"
for node in ${nodes[*]}; do
docker run --name $node --hostname=$node --privileged=true -t -v $VOLUME postmart/psql-9.3:latest & 
done

docker run -p $IP:88:80 --name merlin --hostname="merlin" --privileged=true -t -v $PWD/keys:/keys postmart/psql-9.3:latest &
sleep 2

while [[ -z "$MASTER_IP" ]] || [[  -z "$SLAVE1_IP" ]] || [[ -z "$SLAVE2_IP" ]] || [[ -z "$PGPOOL1_IP" ]] || [[ -z "$PGPOOL2_IP" ]] || [[ -z "$MERLIN_IP" ]] ; do 
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
MERLIN_IP=$(docker inspect merlin | grep IPAddress | awk '{print $2}' | tr -d '",\n')

done

echo "................................"
echo -e "\e[0m"
echo "................................"
#echo "Install Postgresql and openssh"
#docker exec master apt-get -y install postgresql-9.3 postgresql-server-dev-9.3 openssh-server
#docker exec pgpool-2 apt-get -y install postgresql-9.3 postgresql-server-dev-9.3 openssh-server
#docker exec slave1 apt-get -y install postgresql-9.3 postgresql-server-dev-9.3 openssh-server
#docker exec slave2 apt-get -y install postgresql-9.3 postgresql-server-dev-9.3 openssh-server
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
#docker exec master bash -c "sudo -u postgres ssh-keygen -trsa -b 4096"
#docker exec slave1 bash -c "sudo -u postgres ssh-keygen -trsa -b 4096"
#docker exec slave2 bash -c "sudo -u postgres ssh-keygen -trsa -b 4096"

for node in ${nodes[*]}; do
docker exec $node bash -c "sudo -u postgres ssh-keygen  -b 2048 -t rsa -f /var/lib/postgresql/.ssh/id_rsa -q " ;
docker exec $node bash -c "mkdir /root/.ssh/" ;
done

echo "................................"
sleep 1
echo -e "\e[32mAdding entries to /etc/hosts"
echo -e "\e[0m"
echo -e "\e[95m:::::for master"
docker exec master bash -c "echo $SLAVE1_IP slave1 >> /etc/hosts"
docker exec master bash -c "echo $SLAVE2_IP slave2 >> /etc/hosts"
docker exec master bash -c "echo $PGPOOL2_IP pgpool-2 >> /etc/hosts"
docker exec master bash -c "echo $PGPOOL1_IP pgpool-1 >> /etc/hosts"
sleep 1
echo -e "\e[95m:::::for slave1"
docker exec slave1 bash -c "echo $SLAVE2_IP slave2 >> /etc/hosts"
docker exec slave1 bash -c "echo $MASTER_IP master >> /etc/hosts"
docker exec slave1 bash -c "echo $PGPOOL2_IP pgpool-2 >> /etc/hosts"
docker exec slave1 bash -c "echo $PGPOOL1_IP pgpool-1 >> /etc/hosts"
sleep 1
echo -e "\e[95m:::::for slave2"
docker exec slave2 bash -c "echo $MASTER_IP master >> /etc/hosts"
docker exec slave2 bash -c "echo $SLAVE1_IP slave1 >> /etc/hosts"
docker exec slave2 bash -c "echo $PGPOOL2_IP pgpool-2 >> /etc/hosts"
docker exec slave2 bash -c "echo $PGPOOL1_IP pgpool-1 >> /etc/hosts"
sleep 1

echo -e "\e[95m:::::for pgpool-2"
docker exec pgpool-2 bash -c "echo $MASTER_IP master >> /etc/hosts"
docker exec pgpool-2 bash -c "echo $SLAVE1_IP slave1 >> /etc/hosts"
docker exec pgpool-2 bash -c "echo $SLAVE2_IP slave2 >> /etc/hosts"
docker exec pgpool-2 bash -c "echo $PGPOOL1_IP pgpool-1 >> /etc/hosts"
sleep 1

echo -e "\e[95m:::::for pgpool-1"
docker exec pgpool-1 bash -c "echo $MASTER_IP master >> /etc/hosts"
docker exec pgpool-1 bash -c "echo $SLAVE1_IP slave1 >> /etc/hosts"
docker exec pgpool-1 bash -c "echo $PGPOOL2_IP pgpool-2 >> /etc/hosts"
docker exec pgpool-1 bash -c "echo $SLAVE2_IP slave2 >> /etc/hosts"

echo -e "\e[32mcopy ssh keys to shared volume"
echo -e "\e[0m"
docker exec master bash -c "cp /var/lib/postgresql/.ssh/id_rsa.* /keys/master/"
docker exec slave1 bash -c "cp /var/lib/postgresql/.ssh/id_rsa.* /keys/slave1/"
docker exec slave2 bash -c "cp /var/lib/postgresql/.ssh/id_rsa.* /keys/slave2/"
docker exec pgpool-2 bash -c "cp /var/lib/postgresql/.ssh/id_rsa.* /keys/pgpool-2/"
docker exec pgpool-1 bash -c "cp /var/lib/postgresql/.ssh/id_rsa.* /keys/pgpool-1/"

docker exec master bash -c "cat /keys/slave1/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec master bash -c "cat /keys/slave2/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec master bash -c "cat /keys/pgpool-2/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec master bash -c "cat /keys/pgpool-1/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec master bash -c "cp /root/.ssh/authorized_keys /var/lib/postgresql/.ssh/authorized_keys"

docker exec slave1 bash -c "cat /keys/slave2/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec slave1 bash -c "cat /keys/master/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec slave1 bash -c "cat /keys/pgpool-2/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec slave1 bash -c "cat /keys/pgpool-1/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec slave1 bash -c "cp /root/.ssh/authorized_keys /var/lib/postgresql/.ssh/authorized_keys"

docker exec slave2 bash -c "cat /keys/slave1/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec slave2 bash -c "cat /keys/master/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec slave2 bash -c "cat /keys/pgpool-2/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec slave2 bash -c "cat /keys/pgpool-1/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec slave2 bash -c "cp /root/.ssh/authorized_keys /var/lib/postgresql/.ssh/authorized_keys"

docker exec pgpool-2 bash -c "cat /keys/master/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec pgpool-2 bash -c "cat /keys/slave1/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec pgpool-2 bash -c "cat /keys/slave2/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec pgpool-2 bash -c "cat /keys/pgpool-1/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec pgpool-2 bash -c "cp /root/.ssh/authorized_keys /var/lib/postgresql/.ssh/authorized_keys"

docker exec pgpool-1 bash -c "cat /keys/master/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec pgpool-1 bash -c "cat /keys/slave1/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec pgpool-1 bash -c "cat /keys/slave2/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec pgpool-1 bash -c "cat /keys/pgpool-2/id_rsa.pub >> /root/.ssh/authorized_keys"
docker exec pgpool-1 bash -c "cp /root/.ssh/authorized_keys /var/lib/postgresql/.ssh/authorized_keys"
echo "................................"
echo -e "\e[32mtesting ssh"
echo -e "\e[95m:::::::::from slave2 --> "
echo -e "\e[0m"
docker exec slave2 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@slave1"
docker exec slave2 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@master"
docker exec slave2 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@pgpool-2"
sleep 1
echo -e "\e[95m:::::::::from master --> "
echo -e "\e[0m"
docker exec master bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@slave1"
docker exec master bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@slave2"
docker exec master bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@pgpool-2"
sleep 1
echo -e "\e[95m:::::::::from slave1 --> "
echo -e "\e[0m"
docker exec slave1 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@slave2"
docker exec slave1 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@master"
docker exec slave1 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@pgpool-2"
sleep 1
echo -e "\e[95m:::::::::from pgpool-2 --> "
echo -e "\e[0m"
docker exec pgpool-2 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@slave1"
docker exec pgpool-2 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@slave2"
docker exec pgpool-2 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@master"
sleep 1
echo -e "\e[95m:::::::::from pgpool_slave --> "
echo -e "\e[0m"

docker exec pgpool-1 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@slave1"
docker exec pgpool-1 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@slave2"
docker exec pgpool-1 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@master"
docker exec pgpool-1 bash -c "ssh -i /var/lib/postgresql/.ssh/id_rsa -o StrictHostKeyChecking=no postgres@pgpool-2"

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
docker exec pgpool-2 bash -c "echo host all all $MERLIN_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"

docker exec pgpool-1 bash -c "echo host all all $MASTER_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-1 bash -c "echo host all all $SLAVE1_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-1 bash -c "echo host all all $SLAVE2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-1 bash -c "echo host all all $PGPOOL2_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"
docker exec pgpool-1 bash -c "echo host all all $MERLIN_IP/32 trust >> /etc/postgresql/9.3/main/pg_hba.conf"

#docker exec pgpool-2 bash -c "cp /etc/postgresql/9.3/main/pg_hba.conf /etc/pgpool2/pool_hba.conf"

echo -e "\e[95mcreating user database on master"
echo -e "\e[0m"
docker exec master /etc/init.d/postgresql start
#docker exec slave1 /etc/init.d/postgresql start
#docker exec slave2 /etc/init.d/postgresql start
docker exec master bash -c "sudo -u postgres psql --file=/keys/create_user_master.sql "

echo -e "\e[32mCreating base backup  on master"
echo -e "\e[0m"
docker exec master bash -c "/keys/base_backup_master.sh"

echo -e "\e[32mCopy base_backup.tar to slaves"
echo -e "\e[0m"
docker exec master bash -c "sudo -u postgres scp /var/lib/postgresql/9.3/base_backup.tar postgres@slave1:~"
docker exec master bash -c "sudo -u postgres scp /var/lib/postgresql/9.3/base_backup.tar postgres@slave2:~"

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

#docker exec pgpool-2 bash -c "/keys/install.pgpool.admin"
sleep 1
#docker exec pgpool-2 bash -c "/etc/init.d/apache2 start"
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
#docker exec pgpool-2 bash -c "ifconfig eth0:1 $DELEGATE_IP netmask 255.255.0.0"

docker exec pgpool-2 bash -c "/keys/pgpool-2_start.sh"
sleep 3
docker exec pgpool-1 bash -c "/keys/pgpool-2_start.sh"

echo -e "\e[32mExecute psql -f pgpool-recovery.sql template1"
echo -e "\e[0m"
docker exec pgpool-2 bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -f /keys/pgpool-recovery.sql template1"
echo "................................"
