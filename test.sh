DELEGATE_IP=$(cat delegate_ip)

echo -e "\e[32mpreparing test database"
echo -e "\e[33mrunning from app"
echo -e "\e[32mCreate database: testdb1"
echo -e "\e[0m"

shopt -s nocasematch
read -p "Create database 'testdb1' from app using delegated pgpool ip: [y/n]  " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1;;
	y) docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -c 'CREATE DATABASE testdb1;'" \
	&& echo "Successfully created database"  || echo "Failed to create database" ;;
	*) echo "Invalid input" ; exit 1 ;;
esac
sleep 4

echo -e "\e[33mcreating table testtable1 from app"
echo -e "\e[0m"
read -p "Create table 'testtable1: [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'CREATE TABLE testtable1 (i int);'" \
    && echo "Successfully created table" || echo "Failed to create table" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac 
sleep 3

echo -e "\e[32minserting into testtable1 (i int) from app"
echo -e "\e[0m"
read -p "Inserting into 'testtable1: [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'INSERT INTO testtable1 values (0);'" \
&& echo "Seccessfully inserted into table" || echo "Failed to insert into table" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac
sleep 2

echo -e "\e[32m SELECT * from testtable1 from app"
echo -e "\e[0m"
read -p "SELECT * from 'testtable1: [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
	y) docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'SELECT * from testtable1;'" \
&& echo "Success" || echo "Failed selecing from the table" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac
sleep 1

echo -e "\e[32checking replication"
echo -e "\e[32Making sure that testdb1 is replicated on every server"
echo -e "\e[33mrun psql -l on master:"
echo -e "\e[0m"
read -p "Run psql -l on master: [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec master bash -c "sudo -u postgres psql -l" && echo "Success" || echo "Failed" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac

echo -e "\e[33mrun psql -d testdb1 -c SELECT * from testtable1"
echo -e "\e[33mon master"
echo -e "\e[0m"
read -p "SELECT * from testtable1 (running from master): [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec master bash -c "sudo -u postgres psql -d testdb1 -c 'SELECT * from testtable1;'" \
&& echo "Success" || echo "Failed" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac
sleep 1

echo -e "\e[33mrun psql -l on slave1:"
echo -e "\e[0m"
read -p "Run psql -l on slave1: [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec slave1 bash -c "sudo -u postgres psql -l" \
&& echo "Success" || echo "Failed" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac
sleep 1

echo -e "\e[33mrun psql -d testdb1 -c SELECT * from testtable1"
echo -e "\e[33mon slave1"
echo -e "\e[0m"
read -p "SELECT * from testtable1 (running from slave1): [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec slave1 bash -c "sudo -u postgres psql -d testdb1 -c 'SELECT * from testtable1;'" \
&& echo "Success" || echo "Failed" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac
sleep 1

echo -e "\e[33mrun psql -l on slave2:"
echo -e "\e[0m"
read -p "Run psql -l on slave2: [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec slave2 bash -c "sudo -u postgres psql -l" && echo "Success" || echo "Failed" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac
sleep 1

echo -e "\e[33mrun psql -d testdb1 -c 'SELECT * from testtable1"
echo -e "\e[33mon slave2"
echo -e "\e[0m"
read -p "SELECT * from testtable1 (running from slave2): [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec slave2 bash -c "sudo -u postgres psql -d testdb1 -c 'SELECT * from testtable1;'" \
&& echo "Success" || echo "Failed" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac
sleep 1

echo ".............................................."
echo -e "\e[32mTesting failover:"
echo -e "\e[33mStopping postgresql on master"
echo -e "\e[0m"
echo ".............................................."
read -p "Stop postgresql on master: [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec master /etc/init.d/postgresql stop && echo "Success" || echo "Failed" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac
sleep 3

echo -e "\e[33m Inserting values into testable1 from app: INSERT INTO testtable1 values (1)"
echo -e "\e[0m"
sleep 1
read -p "Insert into testtable1 from app: [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'INSERT INTO testtable1 values (1);'" \
&& echo "Success" || echo "Failed" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac
sleep 1

echo "..............................................."
echo -e "\e[33mSELECT * from testtable1"
echo -e "\e[0m"
sleep 1
read -p "SELECT * from testtable1 from app: [y/n]   " ans
case $ans in
	n) echo "Command cancelled, exiting ..." ; exit 1 ;;
    y) docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'SELECT * from testtable1;'" \
&& echo "Success" || echo "Failed" ;;
    *) echo "Invalid input" ; exit 1 ;;
esac

shopt -u nocasematch

echo "..............................................."
echo -e "\e[33mRun ./sh_pool_nodes.sh to verify nodes satus"
echo -e "\e[33mRun ./test_recover_master.sh to recover master"
echo -e "\e[0m"

