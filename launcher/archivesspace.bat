echo off
cd /d %~dp0%

set GEM_HOME=%~dp0%\gems
set GEM_PATH=


java -Darchivesspace-daemon=yes %JAVA_OPTS% -Xss2m -XX:MaxPermSize=256m -Xmx512m -Dfile.encoding=UTF-8 -cp "%GEM_HOME%\gems\jruby-jars-1.7.0\lib\*;%GEM_HOME%\gems\jruby-rack-1.1.12\lib\*;lib\*;launcher\lib\*" org.jruby.Main --1.9 "launcher/launcher.rb" > "logs/archivesspace.out"
