DELEGATE_IP=$(cat delegate_ip)
docker exec app bash -c "sudo -u postgres psql -h $DELEGATE_IP -p 9999 -c 'show pool_nodes;'"
