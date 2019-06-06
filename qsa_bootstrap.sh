#!/bin/bash

cd "`dirname "$0"`"

for i in backend frontend; do
    (
        cd "$i"
        ../scripts/jruby -I../common ../build/gems/bin/bundle update map_validator
        ../scripts/jruby -I../common ../build/gems/bin/bundle update xlsx_streaming_reader
    )
done

build/run bootstrap
