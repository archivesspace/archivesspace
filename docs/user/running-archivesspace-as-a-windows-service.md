---
title: Running ArchivesSpace as a Windows service
layout: en
permalink: /user/running-archivesspace-as-a-windows-service/
---
Running ArchivesSpace as a Windows service requires some additional configuration.

You can use Apache [procrun](http://commons.apache.org/proper/commons-daemon/procrun.html) to configure ArchivesSpace to run as a Windows service. We have provided a service.bat script that will attempt to configure procrun for you (under `launcher\service.bat`).

To run this script, first you need to [download procrun](http://www.apache.org/dist/commons/daemon/binaries/windows/ ).
Extract the files and copy the prunsrv.exe and prunmgr.exe to your ArchivesSpace directory.

To find the path to Java, "Start" > "Control Panel" > "Java", Select "Java" tab. You'll see the path there. It will look something like `C:\Program Files (x86)\Java`

You also need to be sure that Java is in your system path and also to create `JAVA_HOME` as a global environment variable.
To add Java to your path, edit you %PATH% environment variable to include the directory of your java executable ( it will be something like `C:\Program Files (x86)\Java` ). To add `JAVA_HOME`, add a new system variable and put the directory where java was installed ( something like `C:\Program Files (x86)\Java` ).

Environement varialbe be found by  "Start" > "Control Panel" , search for environment. Click "edit the system environment variables". In the section System Variables, find the `PATH` environment variable and select it. Click Edit. If the `PATH` environment variable does not exist, click New. In the Edit System Variable (or New System Variable) window, specify the value of the `PATH` environment variable. Click OK. Close all remaining windows by clicking OK. Do the same for `JAVA_HOME`

Before setting up the ArchivesSpace service, you should also [configure
ArchivesSpace to run against MySQL](http://archivesspace.github.io/archivesspace/user/running-archivesspace-against-mysql/).
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
