---
title: Tuning ArchivesSpace 
layout: en
permalink: /user/tuning-archivesspace/ 
---

ArchivesSpace is a stack of web applications which may require special tuning in order to run most effectively. This is especially the case for institutions with lots of data or many simulatious users editing metadata.
Keep in mind that ArchivesSpace can be hosted on multiple server, either in a [multitenant setup](https://github.com/archivesspace/archivesspace/blob/master/clustering/CLUSTERING_README.md) or by deploying the various applications ( i.e. backend, frontend, public, solr, & indexer ) on seperate servers.

## Application Settings

The application itself can tuned in numerous ways. It’s a good idea to read the [configuring documentation](http://archivesspace.github.io/archivesspace/user/configuring-archivesspace/), as there are numerious settings that can be adjusted to fit your needs.

A important thing to note that since ArchivesSpace is a java application, it’s possible to set the memory allocations used by the JVM. There are numerous articles on the internet full of information about what the optimal settings are, which will depend greatly on the load your server is experiecing and the hardware. It’s a good idea to monitor the application and ensure that it’s not hitting the top limits what you’ve set as the heap.

These settings are:

*   ASPACE_JAVA_XMX : Maximum heap space ( maps to Java’s Xmx, default “Xmx1024m” )
*   ASPACE_JAVA_XSS : Thread stack size ( maps to Xss, default “Xss2m” )
*   ASPACE_JAVA_MAXPERMSIZE : Maximum Permanent generation space ( map to “XX:MaxPermSize”, default “XX:MaxPermSize=256m” )

To modify these settings, Linux users can either export an enironment variable ( e.g. $ export ASPACE_JAVA_XMX=”Xmx2048m” ) or edit the archivesspace.sh startup script and modify the defaults.

Windows users must edit the archivesspace.bat file.

**NOTE: THE APPLICATION WILL NOT USE THE AVAILABLE MEMORY UNLESS YOU SET THE MAXIMUM HEAP SIZE TO ALLOCATE IT** For example, if your server has 4 gigs of RAM, but you haven’t adjusted the ArchivesSpace settings, you’ll only be using 1 gig.

## MySQL

The ArchivesSpace application can hit a MySQL db server rather hard, since it’s a metadatarich application. There are many articles online about how to tune a MySQL database. A good place to start is try something like [MySQL Tuner](http://mysqltuner.com/) or [Tuning Primer](https://rtcamp.com/tutorials/mysql/tuningprimer/) which can give good hints on possible tweaks to make to your MySQL server configuration.

Keep a close eye on the memory available to the server, as well as your InnoDB buffer pool.

## Solr

The internet is full of many suggestions on how to optimize a Solr index. [Running an external Solr index](http://archivesspace.github.io/archivesspace/user/running-archivesspace-with-external-solr/) can be benificial to the performance of ArchivesSpace, since that moves the index to its own server.
