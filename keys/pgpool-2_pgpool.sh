cd /etc/pgpool2/
cp pgpool.conf{,.back}
cp pcp.conf{,.back}
echo pgpool:`pg_md5 pgpool` >> pcp.conf
cp /keys/pgpool-2_pgpool.conf pgpool.conf
cp /keys/basebackup.sh basebackup.sh
cp /keys/pgpool_remote_start pgpool_remote_start
cp /keys/pgpool-recovery pgpool-recovery
