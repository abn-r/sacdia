#!/bin/bash
B=/opt/homebrew/opt/postgresql@18/bin
D=/private/tmp/sacdia-ia61rev-pg
P() { $B/psql -h 127.0.0.1 -p 55465 -U postgres -d sacdia_ia61rev_test -X -q "$@"; }
P -c "show log_min_messages" -c "show log_lock_waits" -c "drop table if exists dl" -c "create table dl(id int primary key, v int)" -c "insert into dl values (1,0),(2,0)"
P -c "begin" -c "update dl set v=1 where id=1" -c "select pg_sleep(1)" -c "update dl set v=1 where id=2" -c "commit" > $D/dl1.out 2>&1 &
sleep 0.3
P -c "begin" -c "update dl set v=2 where id=2" -c "select pg_sleep(1)" -c "update dl set v=2 where id=1" -c "commit" > $D/dl2.out 2>&1
wait
echo "client:"; cat $D/dl1.out $D/dl2.out | grep -i deadlock
echo "server log 'deadlock detected' lines:"; grep -c "deadlock detected" $D/server.log
grep -n "deadlock" $D/server.log | head
