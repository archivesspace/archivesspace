UPGRADING TO 2.1.0 (these considerations also apply when upgrading to any version past 2.1.0 from a version prior to 2.1.0)
==================

Additional upgrade considerations specific to this release. Refer to the [upgrade documentation](https://github.com/archivesspace/archivesspace/blob/master/UPGRADING.md) for the standard instructions that apply in all cases.

# For those upgrading from 1.4.2 and lower

Following the merge of the Container Management Plugin in 1.5.0, ArchivesSpace still retained the old container model and had a number of dependencies on it. This imposed unnecessary complexity and some performance degradation on the system.

In this release all references to the old container model have been removed and the parts of the application that were dependent on it (for example, Imports and Exports) have been refactored to use the new container model.

A consequence of this change is that if you are upgrading from ArchivesSpace version of 1.4.2 or lower, you will need to first upgrade to any version between 1.5.0 and 2.0.1 to run the container conversion. You will then be able to upgrade to 2.1.0. If you are already using any version of ArchivesSpace between 1.5.0 and 2.0.1, you will be able to upgrade directly to 2.1.0. 

# For those needing to migrate data from Archivists' Toolkit or Archon using the migration tools

The migration tools are currently supported through version 1.4.2 only. If you want to migrate data to ArchivesSpace using one of these tools, you must migrate it to 1.4.2. From there you can follow the instructions for those upgrading from 1.4.2 and lower.

# Data migrations in this release

The rights statements data model has changed in 2.1.0. If you currently use rights statements, your data will be converted to the new model during the setup-database step of the upgrade process. We strongly urge you to backup your database and run at least one test upgrade before putting 2.1.0 into production.


# For those using an external Solr server

The index schema has changed with 2.1.0. If you are using an external Solr server, you will need to update the [schema.xml](https://github.com/archivesspace/archivesspace/blob/master/solr/schema.xml) with the newer version. If you are using the default Solr index that ships with ArchivesSpace, no action is needed. 
