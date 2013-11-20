#!/bin/bash

if [[ $0 == /* ]]; then
  self=$0
else
  self="$PWD/$0"
fi

base="$self"
while [ "$base" != "/" ]; do
  base="`dirname "$base"`"
  if [ -e "$base/archivesspace.sh" ]; then
    break
  fi
done

echo $base
