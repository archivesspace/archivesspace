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

# If they pass in $APPCONFIG_DB_URL, we need to check if the other vars that make it up were passed in too
# Otherwise it could lead to defaults and passed in variables causing bad results
url_check=0

if [[ -z $DB_ADDR ]]; then
  DB_ADDR="database"
else
    url_check=$[url_check+1]
fi

if [[ -z $MYSQL_PORT ]]; then
  MYSQL_PORT=3306
else
    url_check=$[url_check+1]
fi

if [[ -z $MYSQL_USER ]]; then
  MYSQL_USER="root"
else
    url_check=$[url_check+1]
fi

if [[ -z $APPCONFIG_DB_URL ]] && [[ "$url_check" -eq "3" ]]; then
    if [[ ! -z $MYSQL_PASSWORD ]]; then
        export APPCONFIG_DB_URL="jdbc:mysql://${DB_ADDR}:${MYSQL_PORT}/archivesspace?useUnicode=true&characterEncoding=UTF-8&user=${MYSQL_USER}&password=${MYSQL_PASSWORD}"
    else
        echo "Error you need to set MYSQL_PASSWORD while using the other MYSQL_XXXX variables."
        exit 1
    fi
else
    echo "Error you have set MYSQL_XXX variables and APPCONFIG_DB_URL, you only can use one or the other."
    exit 1
fi

if [[ -z $MYSQL_DELAY ]]; then
  MYSQL_DELAY=60
fi

if [[ -z $MYSQL_CHECK_INTERVAL ]]; then
  MYSQL_CHECK_INTERVAL=5
fi

counter=0

echo "Waiting up to $MYSQL_DELAY seconds for MySQL. Checking every $MYSQL_CHECK_INTERVAL seconds."

while ! mysql -h "$DB_ADDR" --port="$MYSQL_PORT" --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" -e "show databases;" > /dev/null 2>&1; do
    if [ $counter -gt $MYSQL_DELAY ]; then
        >&2 echo "Error we have been waiting for MySQL too long already; failing."
        exit 1
    fi;

    >&1 echo "Connection failed, retrying in $MYSQL_CHECK_INTERVAL seconds."
    counter=`expr $counter + $MYSQL_CHECK_INTERVAL`
    sleep $MYSQL_CHECK_INTERVAL
done

/archivesspace/scripts/setup-database.sh
if [[ "$?" != 0 ]]; then
  echo "Error running the database setup script."
  exit 1
fi

exec /archivesspace/archivesspace.sh
