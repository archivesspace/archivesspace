UPGRADING TO 2.1.0
==================

Additional upgrade considerations specific to this release. Refer to the [upgrade documentation](http://archivesspace.github.io/archivesspace/user/upgrading-to-a-new-release-of-archivesspace/) for the standard instructions that apply in all cases.

#General overview

The upgrade process to the new data model in 2.1.0 requires considerable data transformation and it is important for users to review this document to understand the implications and possible side-effects.

A quick overview of the steps are:

1. Review this document and understand how the upgrade will impact your data, paying particular attention to the [Preparation section](#preparation) .
2. [Backup your database](http://archivesspace.github.io/archivesspace/user/backup-and-recovery/).
3. No, really, [backup your database](http://archivesspace.github.io/archivesspace/user/backup-and-recovery/).
4. It is suggested that [users start with a new solr index](http://archivesspace.github.io/archivesspace/user/re-creating-indexes/). To do this, delete the data/solr_index/index directory and all files in the data/indexer_state directory.
5. Follow the standard [upgrading instructions](http://archivesspace.github.io/archivesspace/user/upgrading-to-a-new-release-of-archivesspace/). Important to note:  The setup-database.sh|bat script will modify your database schema, but it will not move the data.
6. Start ArchivesSpace. When 2.1.0 starts for the first time, a conversion process will kick off and move the data into the new table structure. **During this time, the application will be unavailable until it completes**. Duration depends on the size of your data and server resources, with a few minutes for very small databases to several hours for very large ones.
7. When the conversion is done, the web application will start and the indexer will rebuild your index. Performance might be slower while the indexer runs, depending on your server environment and available resources.
8. Review the [output of the conversion process](#conversion) following the instructions below. How long it takes for the report to load will depend on the number of entries included in it.

#Preparing for and Converting to the New Container Management Functionality

Following the merge of the Container Management Plugin in 1.5.0, ArchivesSpace still retained the old container model and had a number of dependencies on it. This imposed unnecessary complexity and some performance degradation on the system.

In this release all references to the old container model have been removed and the parts of the application that were dependent on it (for example, Imports and Exports) have been refactored to use the new container model.

A consequence of this change is that if you are upgrading from ArchivesSpace version of 1.4.2 or lower, you will need to upgrade to a version between 1.5.0 and 2.0.1 to run the container conversion, before upgrading to 2.1.0.

##Frequently Asked Questions
*How will my data be converted to the new model?*

When your installation is upgraded to 2.1.0, the conversion will happen as part of the upgrade process.

*I haven’t moved from Archivists’ Toolkit or Archon yet and am planning to use the associated migration tool. Can I migrate directly to 2.1.0?*

No, you must migrate to 1.4.2 or earlier versions of ArchivesSpace and then upgrade your installation to a version between 1.5.0 and 2.0.1 to run the container conversion, before upgrading to 2.1.0.
