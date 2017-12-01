#!/bin/bash

DATA_TMP_DIR=${APPCONFIG_DATA_DIR:-"/archivesspace/data/tmp"}

# http://www.tothenew.com/blog/setting-up-sendmail-inside-your-docker-container/
line=$(head -n 1 /etc/hosts)
line2=$(echo $line | awk '{print $2}')
echo "$line $line2.localdomain" >> /etc/hosts
service sendmail start

# clear out tmp pre-startup as it can build up if persisted
rm -rf $DATA_TMP_DIR/*
/archivesspace/scripts/setup-database.sh
exec /archivesspace/archivesspace.sh
