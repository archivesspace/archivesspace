#!/bin/bash

output="GEM_HOME=\"$GEM_HOME\" GEM_PATH=\"$GEM_PATH\" BUNDLE_PATH=\"$BUNDLE_PATH\""

output="${output} java"

for arg in ${1+"$@"}; do
    output="${output} '$arg' "
done

build_dir="$(cd "`dirname $0`"; pwd)"

cat > "${build_dir}/devserver.sh" <<EOF
#!/bin/bash
#
# This script runs the same command as build/run devserver, allowing
# you to start the devserver outside of Ant (for the sake of using Pry,
# for example)
#
# This file is overwritten whenever you run build/run devserver.

(cd '$PWD'; $output)
EOF

chmod u+x "${build_dir}/devserver.sh"

echo
echo "Devserver startup script written to $build_dir/devserver.sh"
echo

exec java ${1+"$@"}
