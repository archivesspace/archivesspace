@echo off

SETLOCAL ENABLEDELAYEDEXPANSION

cd /d %~dp0%

set ASPACE_LAUNCHER_BASE=%~dp0%
set GEM_HOME=%~dp0%gems
set GEM_PATH=


set JRUBY=
FOR /D %%c IN ("!GEM_HOME!\gems\jruby-*") DO (
  set JRUBY=!JRUBY!;%%c\lib\*
)

REM
REM Check for Java.
REM

java -version
if %ERRORLEVEL% NEQ 0 GOTO NOJAVA
goto STARTUP

:NOJAVA
echo *** Could not run your 'java' executable.
echo *** Please ensure that Java 1.8 or 11 is installed on your machine.
goto END



:STARTUP

echo Writing log file to logs\archivesspace.out
java -Darchivesspace-daemon=yes %JAVA_OPTS% -XX:+CMSClassUnloadingEnabled -XX:+UseConcMarkSweepGC -XX:NewRatio=1 -Xss2m -Xmx1024m -Dfile.encoding=UTF-8 -cp "%GEM_HOME%\gems\jruby-rack-1.1.12\lib\*;lib\*;launcher\lib\*!JRUBY!" org.jruby.Main "launcher/launcher.rb" > "logs/archivesspace.out" 2>&1

:END
