#!/bin/bash

SOLR_URL=${1:-$APPCONFIG_SOLR_URL}

if curl --output /dev/null --silent --head --fail "$SOLR_URL/admin/ping"; then
  curl $SOLR_URL/update?commit=true \
    -H "Content-Type: text/xml" \
    --data-binary '<delete><query>*:*</query></delete>'
else
  echo "SOLR URL does not exist or is not available: ${SOLR_URL}"
fi
