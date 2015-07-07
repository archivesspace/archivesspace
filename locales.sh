#!/bin/bash

OUT=locales.diff
VER=${1:-v1.3.0}

git diff $VER -- common/locales/en.yml > $OUT
git diff $VER -- common/locales/enums/en.yml >> $OUT
git diff $VER -- frontend/config/locales/en.yml >> $OUT
git diff $VER -- frontend/config/locales/help/en.yml >> $OUT
git diff $VER -- public/config/locales/en.yml >> $OUT
