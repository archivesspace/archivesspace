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

REM Running "java -version" both checks that Java is installed and gives us its major version
set JAVA_VERSION_STRING=
for /f "tokens=3" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do set JAVA_VERSION_STRING=%%~v
if "!JAVA_VERSION_STRING!"=="" goto NOJAVA
set JAVA_MAJOR=0
for /f "delims=.-" %%m in ("!JAVA_VERSION_STRING!") do set JAVA_MAJOR=%%m

REM JRuby 9.4 loads native code (jffi) and uses sun.misc.Unsafe; silence the JDK 24+ warnings about it.
REM Each option is only accepted from the Java version shown, so only pass it when the JVM knows it.
set ASPACE_JAVA_MODULE_OPTS=
if !JAVA_MAJOR! GEQ 21 set ASPACE_JAVA_MODULE_OPTS=--enable-native-access=ALL-UNNAMED
if !JAVA_MAJOR! GEQ 23 set ASPACE_JAVA_MODULE_OPTS=!ASPACE_JAVA_MODULE_OPTS! --sun-misc-unsafe-memory-access=allow
goto STARTUP

:NOJAVA
echo *** Could not run your 'java' executable.
echo *** Please ensure that Java 1.7 or 1.8 is installed on your machine.
goto END



:STARTUP

echo Writing log file to logs\archivesspace.out
java -Darchivesspace-daemon=yes %JAVA_OPTS% -XX:NewRatio=1 -Xss2m -Xmx1024m !ASPACE_JAVA_MODULE_OPTS! -Dfile.encoding=UTF-8 -cp "lib\*;launcher\lib\*!JRUBY!" org.jruby.Main "launcher/launcher.rb" > "logs/archivesspace.out" 2>&1

:END
