---
title: Upgrading to a new release of ArchivesSpace 
layout: en
permalink: /user/upgrading-to-a-new-release-of-archivesspace/ 
---

*  **Please also see [UPGRADING_1.1.1.md](https://github.com/archivesspace/archivesspace/blob/master/UPGRADING_1.1.1.md) for special considerations when upgrading to v1.1.1**
*  **Please also see [UPGRADING_1.1.0.md](https://github.com/archivesspace/archivesspace/blob/master/UPGRADING_1.1.0.md) for special considerations when upgrading to v1.1.0**
*  **Please also see [UPGRADING_1.5.0.md](https://github.com/archivesspace/archivesspace/blob/master/UPGRADING_1.5.0.md) for special considerations when upgrading from v1.4.2 to 1..5.x **


## Create a backup of your ArchivesSpace instance

You should make sure you have a working backup of your ArchivesSpace
installation before attempting an upgrade.  Follow the steps
under the *Backup and recovery* section in [README.md](https://github.com/archivesspace/archivesspace/blob/master/README.md) to do this.


## Unpack the new version

It's a good idea to unpack a fresh copy of the version of
ArchivesSpace you are upgrading to.  This will ensure that you are
running the latest versions of all files.  In the examples below,
replace the lower case x with the version number updating to. For example,
1.5.2 or 1.5.3.

For example, on Mac OS X or Linux:

     $ mkdir archivesspace-1.5.x
     $ cd archivesspace-1.5.x
     $ curl -O https://github.com/archivesspace/archivesspace/releases/download/v1.5.x/archivesspace-v1.5.x.zip
     $ unzip -x archivesspace-v1.5.x.zip

( The curl step is optional and simply downloads the distribution from github. You can also
 simply download the zip file in your browser and copy it to the directory )

On Windows, you can do the same by extracting ArchivesSpace into a new
folder you create in Windows Explorer.

## Shut down your ArchivesSpace instance

To ensure you get a consistent copy, you will need to shut down your
running ArchivesSpace instance now.


## Copy your configuration and data files

You will need to bring across the following files and directories from
your original ArchivesSpace installation:

  * the `data` directory
  * the `config` directory (see **Configuration note** below)
  * your `lib/mysql-connector*.jar` file (if using MySQL)
  * any plugins and local modifications you have installed in your `plugins` directory

For example, on Mac OS X or Linux:

     $ cd archivesspace-1.5.x/archivesspace
     $ cp -a /path/to/archivesspace-1.4.2/archivesspace/data/* data/
     $ cp -a /path/to/archivesspace-1.4.2/archivesspace/config/* config/
     $ cp -a /path/to/archivesspace-1.4.2/archivesspace/lib/mysql-connector* lib/
     $ cp -a /path/to/archivesspace-1.4.2/archivesspace/plugins/local plugins/
     $ cp -a /path/to/archivesspace-1.4.2/archivesspace/plugins/wonderful_plugin plugins/

Or on Windows:

     $ cd archivesspace-1.5.x\archivesspace
     $ xcopy \path\to\archivesspace-1.4.2\archivesspace\data\* data /i /k /h /s /e /o /x /y
     $ xcopy \path\to\archivesspace-1.4.2\archivesspace\config\* config /i /k /h /s /e /o /x /y
     $ xcopy \path\to\archivesspace-1.4.2\archivesspace\lib\mysql-connector* lib /i /k /h /s /e /o /x /y
     $ xcopy \path\to\archivesspace-1.4.2\archivesspace\plugins\local plugins\local /i /k /h /s /e /o /x /y
     $ xcopy \path\to\archivesspace-1.4.2\archivesspace\plugins\wonderful_plugin plugins\wonderful_plugin /i /k /h /s /e /o /x /y


Note that you may want to preserve the logs file (`logs/archivesspace.out`
by default) from your previous installation--just in case you need to
refer to it later.

### Configuration note

Sometimes a new release of ArchivesSpace will introduce new
configuration settings that weren't present in previous releases.
Before you replace the distribution `config/config.rb` with your
original version, it's a good idea to review the distribution version
to see if there are any new configuration settings of interest.

Upgrade notes will generally draw attention to any configuration
settings you need to set explicitly, but you never know when you'll
discover a new, exciting feature!  Documentation might also refer to
uncommenting configuration options that won't be in your file if you
keep your older version.


## Transfer your locales data

If you've made modifications to you locales file ( en.yml ) with customized
labels, titles, tooltips, etc., you'll need to transfer those to your new
locale file.

A good way to do this is to use a Diff tool, like Notepad++, TextMate, or just
Linux diff command:

     $ diff /path/to/archivesspace-1.4.2/locales/en.yml /path/to/archivesspace-1.5.x/archivesspace/locales/en.yml
     $ diff /path/to/archivesspace-1.4.2/locales/enums/en.yml /path/to/archivesspace-v1.5.x/archivesspace/locales/enums/en.yml

This will show you the differences in your current locales files, as well as the
new additions in the new version locales files. Simply copy the values you wish
to keep from your old ArchivesSpace locales to your new ArchivesSpace locales
files.

## Run the database migrations

With everything copied, the final step is to run the database
migrations.  This will apply any schema changes and data migrations
that need to happen as a part of the upgrade.  To do this, use the
`setup-database` script for your platform. For example, on Mac OS X
or Linux:

     $ cd archivesspace-1.5.x/archivesspace
     $ scripts/setup-database.sh

Or on Windows:

     $ cd archivesspace-1.5.x\archivesspace
     $ scripts\setup-database.bat

## If you're using external Solr

It's recommeneded you check your version against the version included with
ArchivesSpace:

https://github.com/archivesspace/archivesspace/blob/v1.5.x/build/build.xml#L9

If your version is older than the one provided by ArchivesSpace you may want to
consider upgrading.

Also you should check `schema.xml` and `solrconfig.xml` for changes and update
them if necessary (this is required for proper functionality).

https://github.com/archivesspace/archivesspace/tree/v1.5.x/solr

## If you've deployed to Tomcat

The steps to deploy to Tomcat are esentially the same as in the
[archivesspace_tomcat](https://github.com/archivesspace/archivesspace_tomcat)

But, prior to running your setup-tomcat script, you'll need to be sure to clean out the
any libraries from the previous ASpace version from your Tomcat classpath.

     1. Stop Tomcat
     2. Unpack your new version of ArchivesSpace
     3. Configure your MySQL database in the config.rb ( just like in the
        install instructions )
     4. Make sure all you other local configuration settings are in your
        config.rb file ( check your Tomcat conf/config.rb file for your current
        settings. )
     5. Make sure you MySQL connector jar in the lib directory
     6. Run your setup-database script to migration your database.
     7. Delete all ASpace related jar libraries in your Tomcat's lib directory. These
        will include the "gems" folder, as well as "common.jar" and some
        [others](https://github.com/archivesspace/archivesspace/tree/master/common/lib).
        This will make sure your running the correct version of the dependent
        libraries for your new ASpace version.
        Just be sure not to delete any of the Apache Tomcat libraries.
     8. Run your setup-tomcat script ( just like in the install instructions ).
        This will copy all the files over to Tomcat.
     9. Start Tomcat

## That's it!

You can now start your new ArchivesSpace version as normal.
