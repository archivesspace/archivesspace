#!/bin/bash
# This script is provided AS IS for spec debugging. It is not maintained by the project
# and as meant as a convience and not an offical method for doing anything.
# Please remember that the best bet when debugging a selenium spec is to move it to the
# much more maintainable feature specs.

# Usage: ./build/scripts/pryable_selenium.sh SPEC_NAME
# eg: ./build/scripts/pryable_selenium.sh assessments_spec.rb
# The spec name arguement is optional. If left off, the whole set is run.
# Running the whole set is the only way to make many of the specs pass.


set -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

rm -rf $SCRIPT_DIR/../../frontend/tmp
rm -rf $SCRIPT_DIR/../..//frontend/public/assets
mkdir -p $SCRIPT_DIR/../../frontend/public/assets/00-do-not-put-things-here


export GEM_HOME=$SCRIPT_DIR/../gems \
GEM_PATH="" \
BUNDLE_PATH=$SCRIPT_DIR/../../build/gems \
APPCONFIG_DB_URL="jdbc:mysql://127.0.0.1:3307/archivesspace?useUnicode=true&characterEncoding=UTF-8&user=as&password=as123&useSSL=false&allowPublicKeyRetrieval=true"

/home/ec2-user/.jabba/jdk/openjdk@1.11.0-2/bin/java -Djava.security.egd=file:/dev/./urandom -Xmx2048m -Xss2m \
-Dfile.encoding=UTF-8 -Djavax.accessibility.assistive_technologies= -Daspace.config.search_user_secret=devserver \
-Daspace.config.public_user_secret=devserver -Daspace.config.staff_user_secret=devserver -Daspace.devserver=true \
-Daspace.config.frontend_cookie_secret=devserver -Daspace.config.public_cookie_secret=devserver \
-classpath $SCRIPT_DIR/../../build/jruby-complete:$SCRIPT_DIR/../../build/gems/jruby/3.1.0:$SCRIPT_DIR/../../common:$SCRIPT_DIR/../../common/lib/* \
org.jruby.Main -Iapp/lib $SCRIPT_DIR/migrate_db.rb nuke

/home/ec2-user/.jabba/jdk/openjdk@1.11.0-2/bin/java -Djava.security.egd=file:/dev/./urandom -Xmx2048m -Xss2m \
-Dfile.encoding=UTF-8 -Djavax.accessibility.assistive_technologies= -Daspace.config.search_user_secret=devserver \
-Daspace.config.public_user_secret=devserver -Daspace.config.staff_user_secret=devserver -Daspace.devserver=true \
-Daspace.config.frontend_cookie_secret=devserver -Daspace.config.public_cookie_secret=devserver \
-classpath $SCRIPT_DIR/../../build/jruby-complete-9.4.8.0.jar:$SCRIPT_DIR/../../build/gems/jruby/3.1.0:$SCRIPT_DIR/../../common:$SCRIPT_DIR/../../common/lib/* \
org.jruby.Main -Iapp/lib $SCRIPT_DIR/migrate_db.rb

cd $SCRIPT_DIR/../../frontend
/home/ec2-user/.jabba/jdk/openjdk@1.11.0-2/bin/java -Djava.security.egd=file:/dev/./urandom -Xmx2048m -Xss2m \
-Dfile.encoding=UTF-8 -Djavax.accessibility.assistive_technologies= -Daspace.config.search_user_secret=devserver \
-Daspace.config.public_user_secret=devserver -Daspace.config.staff_user_secret=devserver -Daspace.devserver=true \
-Daspace.config.frontend_cookie_secret=devserver -Daspace.config.public_cookie_secret=devserver \
-classpath $SCRIPT_DIR/../../build/jruby-complete-9.4.8.0.jar:$SCRIPT_DIR/../../build/gems/jruby/3.1.0:$SCRIPT_DIR/../../common:$SCRIPT_DIR/../../common/lib/* \
org.jruby.Main ../build/gems/bin/bundler exec rspec -b --format d --order defined spec/selenium/spec/$1
