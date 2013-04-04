@echo off

SETLOCAL ENABLEDELAYEDEXPANSION

cd /d %~dp0%

set GEM_HOME=%~dp0%\gems
set GEM_PATH=

set JRUBY=
FOR /D %%c IN (!GEM_HOME!\gems\jruby-*) DO (
  set JRUBY=!JRUBY!;%%c\lib\*
)

java -Darchivesspace-daemon=yes %JAVA_OPTS% -Xss2m -XX:MaxPermSize=256m -Xmx512m -Dfile.encoding=UTF-8 -cp "%GEM_HOME%\gems\jruby-rack-1.1.12\lib\*;lib\*;launcher\lib\*!JRUBY!" org.jruby.Main --1.9 "launcher/launcher.rb" > "logs/archivesspace.out"
