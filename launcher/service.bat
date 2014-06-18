@echo off
echo This program will attempt to set up a procrun windows service
echo for ArchivesSpace.
echo
echo Prerequisites:
echo 1) Download procrun
echo  ( http://commons.apache.org/proper/commons-daemon/procrun.html )
echo and put the execuitables ( prunsrv.exe and prunmgr.exe ) 
echo into your archivesspace directory.
echo
echo
echo 2) You must have JAVA_HOME defined as a global variable, pointing 
echo to your systems java home ( e.g. C:\Program Files\Java\jre7 ).
echo To find this, you can use "where java" command. The home will be the
echo directory above "bin\java.exe". 
echo
echo
pause

SETLOCAL ENABLEDELAYEDEXPANSION

cd /d %~dp0%..
set ASPACE_LAUNCHER_BASE=%CD%

REM
REM Check for Java.
REM

java -version
if %ERRORLEVEL% NEQ 0 goto nojava
goto checkJavaHome 

:nojava
echo *** Could not run your 'java' executable.
echo *** Please ensure that Java 1.6 (or above) is installed on your machine.
goto end 

:checkJavaHome
if exist "%JAVA_HOME%" goto checkProcrun
echo You must define JAVA_HOME to point to your installed Java 
echo as a global variable. Please define this and try again
goto end

:checkProcrun
if exist "%ASPACE_LAUNCHER_BASE%\prunsrv.exe" goto setEnv
echo Please download Procrun http://commons.apache.org/proper/commons-daemon/procrun.html  
echo and install the prunsrv.exe into your ArchivesSpace directory.
goto end

:setEnv

copy "%ASPACE_LAUNCHER_BASE%\prunsrv.exe" "%ASPACE_LAUNCHER_BASE%\ArchivesSpaceService.exe"
copy "%ASPACE_LAUNCHER_BASE%\prunmgr.exe" "%ASPACE_LAUNCHER_BASE%\ArchivesSpaceServicew.exe"

set INSTALL_PROCESS="%ASPACE_LAUNCHER_BASE%\ArchivesSpaceService.exe"

set LOG_DIR="%ASPACE_LAUNCHER_BASE%\logs"
set LOG_PREFIX=as_service.out

set AS_LOG="%LOG_DIR%\archivesspace.out"
set AS_ERROR_LOG="%LOG_DIR%\archivesspace_error.out"

set LAUNCHER_SCRIPT="%ASPACE_LAUNCHER_BASE%\launcher\launcher.rb"

set LAUNCHER_LIB="%ASPACE_LAUNCHER_BASE%\launcher\lib"
set LAUNCHER_JARS=
FOR /f %%c in ('dir /b /s %LAUNCHER_LIB%\*.jar') do (
	set LAUNCHER_JARS=!LAUNCHER_JARS!;%%c
)

set AS_LIB="%ASPACE_LAUNCHER_BASE%\lib"
set AS_JARS=
FOR /f %%c in ('dir /b /s %AS_LIB%\*.jar') do (
	set AS_JARS=!AS_JARS!;%%c
)

set GEM_HOME="%ASPACE_LAUNCHER_BASE%\gems"

set JRUBY=
FOR /D %%c IN ("!GEM_HOME!\gems\jruby-*") DO (
  for /f %%a IN ('dir /b /s %%c\lib\*.jar') DO (
	  set JRUBY=!JRUBY!;%%a
  ) 
)
goto :doInstall

:doInstall 
%INSTALL_PROCESS% //IS//ArchivesSpaceService --LogPath=%LOG_DIR% --LogPrefix=%LOG_PREFIX% --StdOutput=%AS_LOG% --StdError=%AS_ERROR_LOG%  --DisplayName="ArchivesSpaceService" --Startup=auto ++JvmOptions=-Darchivesspace-daemon=yes ++JvmOptions=%JAVA_OPTS% --JvmOptions=-Xss2m --JvmOptions=-XX:MaxPermSize=256m --JvmOptions=-Xmx1024m ++JvmOptions=-Dfile.encoding=UTF-8  --Install=%INSTALL_PROCESS% --StartMode=java --StopMode=java --Classpath="!AS_JARS!;!LAUNCHER_JARS!;!JRUBY!" ++StartParams="'%LAUNCHER_SCRIPT%'" --StartClass=org.jruby.Main ++StopParams="'%LAUNCHER_SCRIPT%'; stop" --StopTimeout=5  --StopClass=org.jruby.Main ++Environment='ASPACE_LAUNCHER_BASE=%ASPACE_LAUNCHER_BASE%'
if not errorlevel 1 goto installed
echo "There was a problem installing the service...please check the settings."
goto end
:installed


echo
echo
echo
echo The service has been installed. There is now an
echo ArchivesSpaceService execucitable and ArchivesSpaceServicew monitor.

echo ArchivesSpaceService Options: 
echo ArchivesSpaceService //TS// Run the service as a console app
echo ArchivesSpaceService //RS// Run the service
echo ArchivesSpaceService //SS// Stop the service
echo ArchivesSpaceService //US// Update service pamaters
echo ArchivesSpaceSerivce //DS// Delete service

echo
echo
echo ArchivesSpaceServicew Options:
echo ArchivesSpaceServicew //ES// Start GUI service editor
echo ArchivesSpaceServicew //MS// Monitor service (puts an icon in system tray)
echo
echo Enjoy. 

:end
echo Done 
