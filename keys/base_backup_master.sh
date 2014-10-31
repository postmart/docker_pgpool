cd /var/lib/postgresql/9.3/ ;
sudo -u postgres mkdir archive ; 
sudo -u postgres touch archiving_active ;
sudo -u postgres psql -c "select pg_start_backup('base_backup');" ;
sudo -u postgres tar -cvf base_backup.tar --exclude=pg_xlog --exclude=postmaster.pid main/ ;
sudo -u postgres psql -c "select pg_stop_backup();" 
sudo -u postgres tar -rf base_backup.tar archive

