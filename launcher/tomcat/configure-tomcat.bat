@echo off

SETLOCAL ENABLEDELAYEDEXPANSION

cd /d %~dp0%

set JRUBY=
FOR /D %%c IN (..\gems\gems\jruby-*) DO (
  set JRUBY=!JRUBY!;%%c\lib\*
)


java %JAVA_OPTS% -cp "..\lib\*!JRUBY!" org.jruby.Main --1.9 ..\launcher/tomcat/lib/configure-tomcat.rb %1


