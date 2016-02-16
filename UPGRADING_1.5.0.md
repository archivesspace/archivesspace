UPGRADING TO 1.5.0 
==================

Additional upgrade considerations specific to this release. Refer to the [upgrade documentation](https://github.com/archivesspace/archivesspace/blob/master/UPGRADING.md) for the standard instructions that apply in all cases.

Upgrading to the Container Management data model
-------------

As was requested in the ArchivesSpace [feature voting in
2015](https://archivesspace.atlassian.net/browse/AR-1182), we have
implemented the [Container Management
Plugin](https://github.com/hudmol/container_management) developed by Yale University and [Hudson
Monlongo](http://www.hudsonmolonglo.com/) into the core ArchivesSpace code. You can read more about the original container management plugin
at [ArchivesSpace @ Yale
blog](http://campuspress.yale.edu/yalearchivesspace/2014/11/20/managing-content-managing-containers-managing-access/)

If you are using ArchivesSpace for the first time with version v1.5.0 and are not upgrading from a previous version, you do not need to take any other steps with your install. 

If you are upgrading from a previous version, it is important to note the v1.5.0 migration process has an additional step.
You run the standard setup-database step, which will modify your database
structure to add the additional required tables. When ArchivesSpace v1.5.0
starts for the first time, it will kick-off a conversion process to move data from the previous container
tables into the new container tables. While this process is underway, the
application will be unavailable. 

If you have previously used the container_management plugin, simply run the
update are normal, but be sure to keep 'container_management' in your
AppConfigs[:plugins] setting. This will instruct the application to not attempt
to add the related container_management tables to the database, as well as not
run the top_container conversion process. After you have run the setup-database
and started, you can remove the container_management setting from your
AppConfig[:plugins] settings, if you wish to not have the plugin load on
future restarts. 


**Important: This conversion process will output information indicating
records that might need manual review and cleanup. Keep the output
from the log to inform actions that might be required to fix problematic container
data. Be sure to ask your ArchivesSpace user(s) any questions/concerns you might have about the results of the conversion process.**

As always, it is absolutely critical to backup your data before you begin the update in case
you need to revert to a previous version.
