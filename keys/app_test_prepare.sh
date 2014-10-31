#!/bin/bash
sudo -u postgres psql -p 9999 -c 'CREATE DATABASE testdb1;'
sleep 3
sudo -u postgres psql -p 9999 -d testdb1 -c 'CREATE TABLE table1 (i int) ;'
sleep 1
sudo -u postgres psql -p 9999 -d testdb1 -c 'INSERT INTO table1 values (0);'
sleep 1
sudo -u postgres psql -p 9999 -d testdb1 -c 'SELECT * from table1;'
