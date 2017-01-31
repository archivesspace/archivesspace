@echo off

SETLOCAL ENABLEDELAYEDEXPANSION
set ORIG_PWD=%CD%
cd /d %~dp0%

set ASPACE_LAUNCHER_BASE=%~dp0%\..\
set GEM_HOME=%~dp0%\..\gems

set JRUBY=
FOR /D %%c IN (..\gems\gems\jruby-*) DO (
  set JRUBY=!JRUBY!;%%c\lib\*
)


java %JAVA_OPTS% -cp "..\lib\*!JRUBY!" org.jruby.Main --1.9 ../launcher/backup/lib/backup.rb %*
