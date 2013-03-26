#!/bin/bash
#
# archivesspace          Start the ArchivesSpace archival management system
#
# chkconfig: 2345 90 5
# description: Start the ArchivesSpace archival management system
#

### BEGIN INIT INFO
# Provides: archivesspace
# Required-Start: $local_fs $network $syslog
# Required-Stop: $local_fs $syslog
# Should-Start: $syslog
# Should-Stop: $network $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start the ArchivesSpace archival management system
# Description:       Start the ArchivesSpace archival management system
### END INIT INFO

cd "`dirname $0`"

export ASPACE_LAUNCHER_BASE="$("`dirname $0`"/scripts/find-base.sh)"


ARCHIVESSPACE_USER=

export GEM_HOME="$ASPACE_LAUNCHER_BASE/gems"
export GEM_PATH=

export JAVA_OPTS="-Darchivesspace-daemon=yes $JAVA_OPTS"

# Wow.  Not proud of this!
export JAVA_OPTS="`echo $JAVA_OPTS | sed 's/\([#&;\`|*?~<>^(){}$\,]\)/\\\\\1/g'`"


startup_cmd="java "$JAVA_OPTS"  \
        -Xss2m -XX:MaxPermSize=256m -Xmx512m -Dfile.encoding=UTF-8 \
        -cp \"$GEM_HOME/gems/jruby-jars-1.7.0/lib/*:$GEM_HOME/gems/jruby-rack-1.1.12/lib/*:lib/*:launcher/lib/*\" \
        org.jruby.Main --1.9 \"launcher/launcher.rb\""


case "$1" in
    start)
        shellcmd="bash"
        if [ "$ARCHIVESSPACE_USER" != "" ]; then
            shellcmd="su - $ARCHIVESSPACE_USER"
        fi

        $shellcmd -c "cd '$ASPACE_LAUNCHER_BASE';
          (exec 0<&-; exec 1>&-; exec 2>&-; $startup_cmd &> \"logs/archivesspace.out\" & ) &
          disown $!"

        echo "ArchivesSpace started!  See logs/archivesspace.out for details."
        ;;
    stop)
        pid=`ps -ef | grep 'Darchivesspace-daemon=yes' | grep -v grep | awk '{print $2}' | head -1`
        if [ "$pid" != "" ]; then
            echo -n "Shutting down ArchivesSpace (running as PID $pid)... "
            kill $pid
            echo "done"
        else
            echo "Couldn't find a running instance to stop"
        fi
        ;;
    *)
        # Run in foreground mode
        (cd $ASPACE_LAUNCHER_BASE; bash -c "$startup_cmd")
        ;;
esac
