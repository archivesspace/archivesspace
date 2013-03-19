echo off
cd /d %~dp0%

set GEM_HOME=%~dp0%\..\gems
set GEM_PATH=

java %JAVA_OPTS% -cp "..\gems\gems\jruby-jars-1.7.0\lib\*;..\lib\*" org.jruby.Main --1.9 ..\scripts\rb\migrate_db.rb
