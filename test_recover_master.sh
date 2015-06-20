DELEGATE_IP=$(cat delegate_ip)
# in case initial master went down
docker exec slave1 bash -c "/keys/base_backup_master.sh"
docker exec slave1 bash -c "scp -i /root/.ssh/id_rsa /var/lib/postgresql/9.3/base_backup.tar master:~"
docker exec master bash -c "cp /keys/master_recovery.conf /var/lib/postgresql/9.3/main/recovery.conf"
docker exec master bash -c "/etc/init.d/postgresql start"

echo "test from app:"
docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -d testdb1 -c 'SELECT * from testtable1;'"

echo "test from initial master:"
docker exec master bash -c "sudo -u postgres psql -d testdb1 -c 'SELECT * from testtable1;'"
