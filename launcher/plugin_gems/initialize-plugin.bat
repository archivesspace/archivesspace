@echo off

SETLOCAL ENABLEDELAYEDEXPANSION

cd /d %~dp0..\plugins\%1

set JRUBY=
FOR /D %%c IN (..\..\gems\gems\jruby-*) DO (
  set JRUBY=!JRUBY!;%%c\lib\*
)

set GEM_HOME=gems
java %JAVA_OPTS% -cp "..\..\lib\*!JRUBY!" org.jruby.Main --1.9 -S gem install bundler
java %JAVA_OPTS% -cp "..\..\lib\*!JRUBY!" org.jruby.Main --1.9 -S ..\..\gems\bin\bundle install --gemfile=Gemfile
