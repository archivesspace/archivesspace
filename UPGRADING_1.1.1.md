UPGRADING TO 1.1.1
==================

Additional upgrade considerations specific to this release. Refer to the [upgrade documentation](https://github.com/archivesspace/archivesspace/blob/master/UPGRADING.md) for the standard instructions that apply in all cases.

Resequencing of Archival Object & Digital Object Component trees 
-------------

There have been some scenarios in which archival objects and digital object components lose
some of the information used to order their hierarchy. This can result in issues in creation,
editing, or moving items in the tree, since there are database contraints to ensure uniqueness
of certain metadata elements. 

In order to ensure data integrity, there is now method to resequence the trees. This will
not reorder or edit the elements, but simply rebuild all the technical metadata used to establish
the ordering.

To run the resequencing process, edit the config/config.rb file to have this line: 

```
AppConfig[:resequence_on_startup] = true
```

and restart ArchivesSpace. This will trigger a rebuilding process after the application has 
started. It's advised to let this rebuild process run its course prior to editing records.
This duration depends on the size of your database, which can take seconds ( for databases with
few Archival and Digital Objects ) to hours ( for databases with hundreds of thousands of records ). 
Check your log file to see how the process is going. When it has finished, you should see the application
return to it normal operation, generally with only indexer updates being recorded in the log file. 

After you've started ArchivesSpace, be sure to change the config.rb file to have the :resequence_on_startup
set to "false", since you will not need to run this process on every restart. 

Export PDFs in the Public Interface
-------------

A common request has been to have PDF version of the EAD exported in the public application.
This has been a bit problematic, since EAD export has a rather large resource hit on the 
database, which is only increased by the added process of PDF creation. We are currently 
redesigning part of the ArchivesSpace backend to make PDF creation more user friendly by 
establishing a queue system for exports. 

In the meantime, Mark Cooper at Lyrasis has made a [ Public Metadata Formats plugin ]( https://github.com/archivesspace/aspace-public-formats )  
that exposes certain metadata formats and PDFs in the public UI. This plugin has been included
in this release, but you will need to configure it to expose which formats you would like
to have exposed. Please read the plugin documentation on how to configure this. 

PLEASE NOTE: 
Exporting large EAD resources with this plugin will most likely cause some problems. Long requests
will timeout, since the server does not want to waste resources on long running processes.
In addition, large number of requests for PDFs can cause an increase load on the server.
Please be aware of the issues and limitations of this plugin before enabling it. 



---