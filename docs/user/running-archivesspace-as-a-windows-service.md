---
title: Running ArchivesSpace as a Windows Service 
layout: en
permalink: /user/running-archivesspace-as-a-windows-service/ 
---

Running ArchivesSpace as a Windows service requires some additional 
configuration. 

You can also use Apache [procrun]((http://commons.apache.org/proper/commons-daemon/procrun.html) to configure ArchivesSpace. We have 
provided a service.bat script that will attempt to configure 
procrun for you (under `launcher\service.bat`). 

To run this script, first you need to [download procrun](http://www.apache.org/dist/commons/daemon/binaries/windows/ ).
Extract the files and copy the prunsrv.exe and prunmgr.exe to your
ArchivesSpace directory. 

You also need to be sure that Java in your system path and also to set `JAVA_HOME` as a global environment variable. 
To add Java to your path, edit you %PATH% environment variable to include the directory of
your java executable ( it will be something like `C:\Program Files
(x86)\Java\bin` ). To add `JAVA_HOME`, add a new system variable and put the
directory where java was installed ( something like `C:\Program Files
(x86)\Java` ).

Before setting up the ArchivesSpace service, you should also [configure
ArchivesSpace to run against MySQL](https://github.com/archivesspace/archivesspace#running-archivesspace-against-mysql).
Be sure that the MySQL connector jar file is in the lib directory, in order for
the service setup script to add it to the application's classpath.

Lastly, for the service to shutdown cleanly, uncomment and change these lines in
config/config.rb: 

    AppConfig[:use_jetty_shutdown_handler] = true 
    AppConfig[:jetty_shutdown_path] = "/xkcd"

This enables a shutdown hook for Jetty to respond to when the shutdown action
is taken. 

You can now execute the batch script from your ArchivesSpace root directory from
the command line with `launcher\service.bat`. This  will configure the service and
provide two executables: `ArchivesSpaceService.exe` (the service) and
`ArchivesSpaceServicew.exe` (a GUI monitor)

There are several options to launch the service. The easiest is to open the GUI
monitor and click "Launch".

Alternatively, you can start the GUI monitor and minimize it in your
system tray with:

    ArchivesSpaceServicew.exe //MS//

To execute the service from the command line, you can invoke:

    ArchivesSpaceService.exe //ES// 

Log output will be placed in your ArchivesSpace log directory.

Please see the [procrun
documentation](http://commons.apache.org/proper/commons-daemon/procrun.html)
for more information. 

