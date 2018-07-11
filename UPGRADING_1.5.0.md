UPGRADING TO 1.5.0 
===============================================================================================

Additional upgrade considerations specific to this release, which also apply to upgrading from 1.4.2 or lower to any version through 2.0.1. Refer to the [upgrade documentation](http://archivesspace.github.io/archivesspace/user/upgrading-to-a-new-release-of-archivesspace/) for the standard instructions that apply in all cases.

# General overview

The upgrade process to the new data model in 1.5.0 requires considerable data transformation and it is important for users to review this document to understand the implications and possible side-effects. 

A quick overview of the steps are:

1. Review this document and understand how the upgrade will impact your data, paying particular attention to the [Preparation section](#preparation) .
2. [Backup your database](http://archivesspace.github.io/archivesspace/user/backup-and-recovery/).
3. No, really, [backup your database](http://archivesspace.github.io/archivesspace/user/backup-and-recovery/).
4. It is suggested that [users start with a new solr index](http://archivesspace.github.io/archivesspace/user/re-creating-indexes/). To do this, delete the data/solr_index/index directory and all files in the data/indexer_state directory. The embedded version of Solr has been upgraded, which should result in a much more compact index size. 
5. Follow the standard [upgrading instructions](http://archivesspace.github.io/archivesspace/user/upgrading-to-a-new-release-of-archivesspace/). Important to note:  The setup-database.sh|bat script will modify your database schema, but it will not move the data. If you are currently using the container management plugin you will need to remove it from the list of plugins in your config file prior to starting ArchivesSpace.
6. Start ArchivesSpace. When 1.5.0 starts for the first time, a conversion process will kick off and move the data into the new table structure. **During this time, the application will be unavailable until it completes**. Duration depends on the size of your data and server resources, with a few minutes for very small databases to several hours for very large ones. 
7. When the conversion is done, the web application will start and the indexer will rebuild your index. Performance might be slower while the indexer runs, depending on your server environment and available resources. 
8. Review the [output of the conversion process](#conversion) following the instructions below. How long it takes for the report to load will depend on the number of entries included in it.

# Preparing for and Converting to the New Container Management Functionality

With version 1.5.0, ArchivesSpace is adopting a new data model that will enable more capable and efficient management of the containers in which you store your archival materials.  To take advantage of this improved functionality:
* Repositories already using ArchivesSpace as a production application will need to upgrade their ArchivesSpace applications to the version 1.5.0.  (This upgrade / conversion must be done to take advantage of any other new features / bug fixes in ArchivesSpace 1.5.0 or later versions.)
* Repositories not yet using ArchivesSpace in production but needing to migrate data from the Archivists’ Toolkit or Archon will need to migrate their data to version 1.4.2 of ArchivesSpace or earlier and then upgrade that version to version 1.5.0.  (This can be done when your repository is ready to migrate to ArchivesSpace.) 
* Repositories not yet using ArchivesSpace in production and not needing to migrate data from the Archivists’ Toolkit or Archon can start using Archivists 1.5.0 without the need of upgrading.  (People in this situation do not need to read any further.)
 
Converting the container data model in version 1.4.2 and earlier versions of ArchivesSpace to the 1.5.0 version has some complexity and may not accommodate all the various ways in which container information has been recorded by diverse repositories.  As a consequence, upgrading from a pre-1.5.0 version of ArchivesSpace requires planning for the upgrade, reviewing the results, and, possibly, remediating data either prior to or after the final conversion process.  Because of all the variations in which container information can be recorded, it is impossible to know all the ways the data of repositories will be impacted.  For this reason, **all repositories upgrading their ArchivesSpace to version 1.5.0 should do so with a backup of their production ArchivesSpace instance and in a test environment.** A conversion may only be undone by reverting back to the source database.

## Frequently Asked Questions
*How will my data be converted to the new model?*

When your installation is upgraded to 1.5.0, the conversion will happen as part of the upgrade process.

*Can I continue to use the current model for containers and not convert to the new model?*

Because it is such a substantial improvement [(see separate announcement for the new features)](https://github.com/archivesspace/archivesspace/blob/master/README_FEATURES_1.5.0.md), the new model is required for all using ArchivesSpace 1.5.0 and higher. The only way to continue using the current model is to never upgrade beyond 1.4.2.

*What if I’m already using the container management plugin made available to the community by Yale University?*

Conversion of data created using the Yale container management plugin, or a local adaptation of the plugin, will also happen as part of the process of upgrading to 1.5.0. Some steps will be skipped when they are not needed.  At the end of the process, the new container data model will be integrated into your ArchivesSpace and will not need to be loaded or maintained as a plugin.

Those currently running the container management plugin will need to remove the container management plugin from the list in your config file prior to starting the conversion or a validation name error will occur.

*I haven’t moved from Archivists’ Toolkit or Archon yet and am planning to use the associated migration tool. Can I migrate directly to 1.5.0?*

No, you must migrate to 1.4.2 or earlier versions and then upgrade your installation to 1.5.0 according to the instructions provided here.

*What changes are being made to the previous model for containers?*

The biggest change is the new concept of top containers. A top container is the highest level container in which a particular instance is stored. Top containers are in some ways analogous to the current Container 1, but broken out from the entire container record (child and grandparent container records).  As such, top containers enable more efficient recording and updating of the highest level containers in your collection.

*How does ArchivesSpace determine what is a top container?*

During the conversion, ArchivesSpace will find all the Container 1s in your current ArchivesSpace database. It will then evaluate them as follows:
* If containers have barcodes, one top container is created for each unique Container 1 barcode.
* If containers do not have barcodes, one top container is created for each unique combination of container 1 indicator and container type 1 within a resource or accession.
* Once a top container is created, additional instance records for the same container within an accession or resource will be linked to that top container record.

## Preparation <a name="preparation"></a>

*What can I do to prepare my ArchivesSpace data for a smoother conversion to top containers?*

* If your Container 1s have unique barcodes, you do not need to do anything except verify that your data is complete and accurate. You should run a preliminary conversion as described in the Conversion section and resolve any errors.
* If your Container 1s do not have barcodes, but have a nonduplicative container identifier sequence within each accession or resource (e.g. Box 1, Box 2, Box 3), or the identifiers are only reused within an accession or resource for different types of containers (for example, you have a Box 1 through 10 and an Oversize Box 1 through 3) you do not need to do anything except verify that your data is complete and accurate. You should run a preliminary conversion as described in the Conversion section and resolve any errors.
* If your Container 1s do not have barcodes and you have parallel numbering sequences, where the same indicators and types are used to refer to different containers within the same accession or resource within some or all accessions or resources (for example, you have a Box 1 in series 1 and a different Box 1 in series 5) you will need to find a way to uniquely identify these containers. One option is to run this [barcoder plugin](https://github.com/archivesspace/barcoder) for each resource to which this applies. The barcoder plugin creates barcodes that combine the ID of the highest level archival object ancestor with the container 1 type and indicator. (The barcoder plugin is designed to run against one resource at a time, instead of against all resources, because not all resources in a repository may match this condition.) Once you’ve differentiated your containers with parallel number sequences, you should run a preliminary conversion as described in the Conversion section and resolve any errors.
 
You do not need to make any changes to Container 2 fields or Container 3 fields. Data in these fields will be converted to the new Child and Grandchild container fields that map directly to these fields.

If you use the current Container Extent fields, these will no longer be available in 1.5.0. Any data in these fields will be migrated to a new Extent sub-record during the conversion. You can evaluate whether this data should remain in an extent record or if it belongs in a container profile or other fields and then move it accordingly after the conversion is complete.

*I have EADs I still need to import into ArchivesSpace. How can I get them ready for this new model?*

If you have a box and folder associated with a component (or any other hierarchical relationship of containers), you will need to add identifiers to the container element so that the EAD importer knows which is the top container. If you previously used Archivists' Toolkit to create EAD, your containers probably already have container identifiers. If your container elements do not have identifiers already, Yale University has made available an [XSLT transformation file](https://github.com/YaleArchivesSpace/xslt-files/blob/master/EAD_add_IDs_to_containers.xsl) to add them. You will need to run it before importing the EAD file into ArchivesSpace. 

## Conversion <a name="conversion"></a> 

When upgrading from 1.4.2 (and earlier versions) to 1.5.0, the container conversion will happen as part of the upgrade process. You will be able to follow its progress in the log. Instructions for upgrading from a previous version of ArchivesSpace are available at [https://github.com/archivesspace/archivesspace/blob/master/UPGRADING.md]. 

Because this is a major change in the data model for this portion of the application, running at least one test conversion is very strongly recommended. Follow these steps to run the upgrade/conversion process:
* Create a backup of your ArchivesSpace instance to use for testing. **IT IS ESSENTIAL THAT YOU NOT RUN THIS ON A PRODUCTION INSTANCE AS THE CONVERSION CHANGES YOUR DATA, and THE CHANGES CANNOT BE UNDONE EXCEPT BY REVERTING TO A BACKUP VERSION OF YOUR DATA PRIOR TO RUNNING THE CONVERSION.**
* Follow the upgrade instructions to unpack a fresh copy of the v 1.5.0 release made available for testing, copy your configuration and data files, and transfer your locales.
* **It is recommended that you delete your Solr index files to start with a fresh index** We are upgrading the version of Solr that ships with the application, and the upgrade will require a total reindex of your ArchivesSpace data. To do this, delete the data/solr_index/index directory and the files in data/indexer_state.  
* Follow the upgrade instructions to run the database migrations. As part of this step, your container data will be converted to the new data model. You can follow along in the log. Windows users can open the archivesspace.out file in a tool like Notepad ++. Mac users can do a tail –f logs/archivesspace.out to get a live update from the log.
* When the test conversion has been completed, the log will indicate "Completed: existing containers have been migrated to the new container model." 

 ![Image of Conversion Log](https://github.com/archivesspace/archivesspace/blob/master/docs/ConversionLog.png)

* Open ArchivesSpace via your browser and login.
Retrieve the container conversion error report from the Background Jobs area:
* Select Background Jobs from the Settings menu.

![Image of Background Jobs](https://github.com/archivesspace/archivesspace/blob/master/docs/BackgroundJobs.png)
 
* The first item listed under Archived Jobs after completing the upgrade should be container_conversion_job. Click View. 

![Image of Background Jobs List](https://github.com/archivesspace/archivesspace/blob/master/docs/BackgroundJobsList.png)

* Under Files, click File to download a CSV file with the errors and a brief explanation.

![Image of Files](https://github.com/archivesspace/archivesspace/blob/master/docs/Files.png)

![Image of Error Report](https://github.com/archivesspace/archivesspace/blob/master/docs/ErrorReport.png)
 
* Go back to your source data and correct any errors that you can before doing another test conversion.
* When the error report shows no errors, or when you are satisfied with the remaining errors, your production instance is ready to be upgraded.
* When the final upgrade/conversion is complete, you can move ArchivesSpace version 1.5.0 into production.

*What are some common errors or anomalies that will be flagged in the conversion?*

* A container with a barcode has different indicators or types in different records.
* A container with a particular type and indicator sometimes has a barcode and sometimes doesn’t.
* A container is missing a type or indicator.
* Container levels are skipped (for example, there is a Container 1 and a Container 3, but no Container 2).
* A container has multiple locations.
 
The conversion process can resolve some of these errors for you by supplying or deleting values as it deems appropriate, but for the most control over the process you will most likely want to resolve such issues yourself in your ArchivesSpace database before converting to the new container model.

*Are there any known conversion issues?*

Due to a change in the ArchivesSpace EAD importer in 2015, some EADs with hierarchical containers not designated by a @parent attribute were turned into multiple instance records. This has since been corrected in the application, but we are working on a plugin (now available at [https://github.com/archivesspace/instance_joiner]) that will enable you to turn these back into single instances so that subcontainers are not mistakenly turned into top containers.
