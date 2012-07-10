#!/bin/sh

# Post a Collection Record

asresponse=`curl -X POST -d @data/collection.json http://127.0.0.1:4567/collections`
echo $asresponse