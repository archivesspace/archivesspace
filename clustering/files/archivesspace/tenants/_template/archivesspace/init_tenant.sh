#!/bin/bash

version="$1"
base="`pwd`"
tenant=$(basename `dirname $base`)

if [ "$version" == "" ]; then
    echo "Usage: $0 <software version to use>"
    exit
fi

dir="/aspace/archivesspace/software/$version"

if [ ! -e "$dir" ]; then
  echo "$dir doesn't exist"
  exit
fi

cd "`dirname $0`"

if [ ! -e "version" ]; then
    mv config config.template

    ln -s $dir version
    ln -s $PWD/version/* .
    rm -f config data logs

    mv config.template config
    ln -s /aspace.local/tenants/$tenant/{logs,data} .
fi

mkdir -p /aspace.local/tenants/$tenant/{logs,data}

