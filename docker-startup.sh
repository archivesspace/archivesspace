#!/bin/bash

DATA_TMP_DIR="${APPCONFIG_DATA_DIR:-"/archivesspace/data"}/tmp"

# DEPLOY_PKG (optional): [./config/config.rb, ./plugins, ./stylesheets]
if [[ -v ASPACE_DEPLOY_PKG_URL ]]; then
  wget -O /deploy_pkg.zip $ASPACE_DEPLOY_PKG_URL
  if [[ "$?" != 0 ]]; then
    echo "Error downloading deploy package from: $ASPACE_DEPLOY_PKG_URL"
    exit 1
  else
    unzip -o /deploy_pkg.zip -d /tmp
    cp /tmp/config/config.rb /archivesspace/config/config.rb || true
    cp -r /tmp/plugins/* /archivesspace/plugins/ || true
    cp /tmp/stylesheets/* /archivesspace/stylesheets/ || true
  fi
fi

# INITIALIZE PLUGINS (optional): ASPACE_INITIALIZE_PLUGINS=plugin1,plugin2,plugin3
if [[ -v ASPACE_INITIALIZE_PLUGINS ]]; then
  for plugin in ${ASPACE_INITIALIZE_PLUGINS//,/ }
  do
    echo "Initializing plugin: $plugin"
    /archivesspace/scripts/initialize-plugin.sh $plugin
  done
fi

# http://www.tothenew.com/blog/setting-up-sendmail-inside-your-docker-container/
line=$(head -n 1 /etc/hosts)
line2=$(echo $line | awk '{print $2}')
echo "$line $line2.localdomain" >> /etc/hosts
service sendmail start

# clear out tmp pre-startup as it can build up if persisted
rm -rf $DATA_TMP_DIR/*
/archivesspace/scripts/setup-database.sh
exec /archivesspace/archivesspace.sh
