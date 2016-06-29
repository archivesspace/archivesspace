#!/bin/bash

OUT=locales.diff
VER=${1:-v1.4.2}

declare -a locales=(
  "common/locales/en.yml"
  "common/locales/enums/en.yml"
  "frontend/config/locales/en.yml"
  "frontend/config/locales/help/en.yml"
  "public/config/locales/en.yml"
)

truncate -s 0 $OUT

for i in "${locales[@]}"
do
   git diff --ignore-space-at-eol -b -w $VER -- "$i" >> $OUT
done

echo "Created diff: ${OUT}"
exit 0
