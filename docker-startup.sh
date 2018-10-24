#!/bin/bash

DATA_TMP_DIR="${APPCONFIG_DATA_DIR:-"/archivesspace/data"}/tmp"

# DEPLOY_PKG (optional): [./config/config.rb, ./plugins, ./stylesheets]
if [[ -v ASPACE_DEPLOY_PKG_URL ]]; then
  wget -O /archivesspace/deploy_pkg.zip $ASPACE_DEPLOY_PKG_URL
  if [[ "$?" != 0 ]]; then
    echo "Error downloading deploy package from: $ASPACE_DEPLOY_PKG_URL"
    exit 1
  else
    unzip -o /archivesspace/deploy_pkg.zip -d /archivesspace/tmp
    cp /archivesspace/tmp/config/config.rb /archivesspace/config/config.rb || true
    cp -r /archivesspace/tmp/plugins/* /archivesspace/plugins/ || true
    cp /archivesspace/tmp/stylesheets/* /archivesspace/stylesheets/ || true
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

# clear out tmp pre-startup as it can build up if persisted
rm -rf $DATA_TMP_DIR/*
/archivesspace/scripts/setup-database.sh
exec /archivesspace/archivesspace.sh
