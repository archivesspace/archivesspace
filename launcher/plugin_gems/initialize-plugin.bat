@echo off

SETLOCAL ENABLEDELAYEDEXPANSION

cd /d %~dp0..\plugins\%1

for /d %%a in (..\..\gems\gems\bundler-*) do set bnm=%%a
for /f "tokens=1* delims=-" %%a in ("%bnm%") do set vers=%%b

set JRUBY=
FOR /D %%c IN (..\..\gems\gems\jruby-*) DO (
  set JRUBY=!JRUBY!;%%c\lib\*
)

set GEM_HOME=gems
java %JAVA_OPTS% -cp "..\..\lib\*!JRUBY!" org.jruby.Main -S gem install bundler -v "%vers%"
java %JAVA_OPTS% -cp "..\..\lib\*!JRUBY!" org.jruby.Main -S ..\..\gems\bin\bundle install --gemfile=Gemfile
