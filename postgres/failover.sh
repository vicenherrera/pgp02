#!/bin/bash

FAILED_NODE_ID=$1
FAILED_HOST=$2
FAILED_PORT=$3
FAILED_DATADIR=$4
OLD_PRIMARY_ID=$5
NEW_PRIMARY_HOST=$6
NEW_PRIMARY_PORT=$7

LOGFILE="/var/log/pgpool_failover.log"

echo "$(date): Failover triggered. Failed node: $FAILED_HOST, New primary: $NEW_PRIMARY_HOST" >> $LOGFILE

# Si el nodo caído era el primary
if [ "$FAILED_NODE_ID" -eq "$OLD_PRIMARY_ID" ]; then

    echo "$(date): Primary failed. Promoting standby $NEW_PRIMARY_HOST" >> $LOGFILE

      # Promover el nuevo primary
    ssh postgres@$NEW_PRIMARY_HOST "pg_ctl -D /data/main promote"

    sleep 5
    echo "$(date): Promotion done on $NEW_PRIMARY_HOST" >> $LOGFILE

      # Reconfigurar los otros nodos como standby
    for NODE in 172.16.1.238 172.16.1.239 172.16.1.240
    do
     if [ "$NODE" != "$NEW_PRIMARY_HOST" ]; then
          echo "$(date): Reconfiguring standby $NODE" >> $LOGFILE
          ssh postgres@$NODE "
             sed -i \"s/host=.*/host=$NEW_PRIMARY_HOST/\" /data/main/postgresql.auto.conf
             systemctl restart postgresql
          "
     fi
    done
fi
exit 0
