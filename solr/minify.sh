#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

tidy -quiet -asxml -xml -indent -wrap 1024 --hide-comments 1 \
  $SCRIPT_DIR/_default-schema-8.8.xml > $SCRIPT_DIR/_default-schema-8.8.min.xml

tidy -quiet -asxml -xml -indent -wrap 1024 --hide-comments 1 \
  $SCRIPT_DIR/_default-solrconfig-8.8.xml > $SCRIPT_DIR/_default-solrconfig-8.8.min.xml

tidy -quiet -asxml -xml -indent -wrap 1024 --hide-comments 1 \
  $SCRIPT_DIR/schema-8.8.xml > $SCRIPT_DIR/schema-8.8.min.xml

tidy -quiet -asxml -xml -indent -wrap 1024 --hide-comments 1 \
  $SCRIPT_DIR/solrconfig-8.8.xml > $SCRIPT_DIR/solrconfig-8.8.min.xml
