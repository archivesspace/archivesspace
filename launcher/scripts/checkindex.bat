@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

cd /d %~dp0%

set GEM_HOME=%~dp0%\..\gems
set GEM_PATH=

set JRUBY=
FOR /D %%c IN (..\gems\gems\jruby-*) DO (
  set JRUBY=!JRUBY!;%%c\lib\*
)

java %JAVA_OPTS% -cp "..\lib\*!JRUBY!" org.jruby.Main --1.9 ..\scripts\rb\checkindex.rb %*
