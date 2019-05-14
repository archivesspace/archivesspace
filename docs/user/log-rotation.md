---
title: Log Rotation
layout: en
permalink: /user/log-rotation/
---
In order to prevent your ArchivesSpace log file from growing excessively, you can set up log rotation. How to set up log rotation is specific to your institution but here is an example logrotate config file with an explanation of what it does. 

`/etc/logrotate.d/`

````
  /<install location>/archivesspace/logs/archivesspace.out {
          daily
          rotate 7
          compress
          notifempty
          missingok
          copytruncate
   }
   ````
   this example configuration file:
   * rotates the logs daily
   * keeps 7 days worth of logs
   * compresses the logs so they take up less space
   * ignores empty logs
   * does not report errors if the log file is missing
   * creates a copy of the original log file for rotation before truncating the contents of the original file
