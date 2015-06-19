DELEGATE_IP=$(cat delegate_ip)
echo -e "\e[32mpreparing test database"
echo -e "\e[33mrunning from app"
echo -e "\e[32mCreate database: testdb1"
echo -e "\e[0m"
docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -c 'CREATE DATABASE testdb1;'"
sleep 3

echo -e "\e[33mcreating table testtable1 from app"
echo -e "\e[0m"
docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'CREATE TABLE testtable1 (i int);'"
sleep 3

echo -e "\e[32minserting into testtable1 (i int) from app"
echo -e "\e[0m"
docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'INSERT INTO testtable1 values (0);'"
sleep 2

echo -e "\e[32m SELECT * from testtable1"
echo -e "\e[0m"
docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'SELECT * from testtable1;'"
sleep 1

echo -e "\e[32checking replication"
echo -e "\e[32Making sure that testdb1 is replicated on every server"
echo -e "\e[33mrun psql -l on master:"
echo -e "\e[0m"
docker exec master bash -c "sudo -u postgres psql -l"

echo -e "\e[33mrun psql -d testdb1 -c SELECT * from testtable1"
echo -e "\e[33mon master"
echo -e "\e[0m"
docker exec master bash -c "sudo -u postgres psql -d testdb1 -c 'SELECT * from testtable1;'"
sleep 1

echo -e "\e[33mrun psql -l on slave1:"
echo -e "\e[0m"
docker exec slave1 bash -c "sudo -u postgres psql -l"
sleep 1

echo -e "\e[33mrun psql -d testdb1 -c SELECT * from testtable1"
echo -e "\e[33mon slave1"
echo -e "\e[0m"
docker exec slave1 bash -c "sudo -u postgres psql -d testdb1 -c 'SELECT * from testtable1;'"
sleep 1

echo -e "\e[33mrun psql -l on slave2:"
echo -e "\e[0m"
docker exec slave2 bash -c "sudo -u postgres psql -l"
sleep 1
echo -e "\e[33mrun psql -d testdb1 -c 'SELECT * from testtable1"
echo -e "\e[33mon slave2"
echo -e "\e[0m"
docker exec slave2 bash -c "sudo -u postgres psql -d testdb1 -c 'SELECT * from testtable1;'"

sleep 1
echo ".............................................."
echo -e "\e[32mTesting failover:"
echo -e "\e[33mStopping postgresql on master"
echo -e "\e[0m"
echo ".............................................."
docker exec master /etc/init.d/postgresql stop
sleep 3

echo -e "\e[33m Inserting values into testable1 from app server: INSERT INTO testtable1 values (1)"
echo -e "\e[0m"
sleep 1
docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'INSERT INTO testtable1 values (1);'"
sleep 1
echo "..............................................."
echo -e "\e[33mSELECT * from testtable1"
echo -e "\e[0m"
sleep 1
docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'SELECT * from testtable1;'"

