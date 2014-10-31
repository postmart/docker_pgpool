/usr/sbin/pgpool  -f /etc/pgpool2/pgpool.conf > pgpool.log 2>&1 &
#/etc/init.d/pgpool2 start
sleep 5
pcp_node_count 10 localhost 9898 pgpool pgpool
pcp_node_info 10 localhost 9898 pgpool pgpool 0
pcp_node_info 10 localhost 9898 pgpool pgpool 1
pcp_node_info 10 localhost 9898 pgpool pgpool 2
