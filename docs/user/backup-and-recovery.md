---
title: Backup and recovery 
layout: en
permalink: /user/backup-and-recovery/ 
---

## Creating backups using the provided script

ArchivesSpace provides some simple scripts for backing up a single
instance to a `.zip` file.  You can run:

     scripts/backup.sh --output /path/to/backup-yyyymmdd.zip

and the script will generate a file containing:

  * A snapshot of the demo database (if you're using the demo
    database)
  * A snapshot of the Solr index and related indexer files

If you are running against MySQL and have `mysqldump` installed, you
can also provide the `--mysqldump` option.  This will read the
database settings from your configuration file and add a dump of your
MySQL database to the resulting `.zip` file.


## Managing your own backups

If you want more control over your backups, you can develop your own
scripts.  ArchivesSpace stores all persistent data in the database, so
as long as you have backups of your database then you can always
recover.

If you are running MySQL, the `mysqldump` utility can dump the database
schema and data to a file.  It's a good idea to run this with the
`--single-transaction` option to avoid locking your database tables
while your backups run. It is also essential to use the `--routines`
flag, which will include functions and stored procedures in the
backup (which ArchivesSpace uses at least for Jasper reports).

If you are running with the demo database, you can create periodic
database snapshots using the following configuration settings:

     # In this example, we create a snapshot at 4am each day and keep
     # 7 days' worth of backups
     #
     # Database snapshots are written to 'data/demo_db_backups' by
     # default.
     AppConfig[:demo_db_backup_schedule] = "0 4 * * *"
     AppConfig[:demo_db_backup_number_to_keep] = 7

Solr indexes can always be recreated from the contents of the
database, but backing them up can reduce your recovery time if
disaster strikes.  You can create periodic Solr snapshots using the
following configuration settings:

     # Create one snapshot per hour and keep only one.
     #
     # Solr snapshots are written to 'data/solr_backups' by default.
     AppConfig[:solr_backup_schedule] = "0 * * * *"
     AppConfig[:solr_backup_number_to_keep] = 1


## Recovering from backup

When recovering an ArchivesSpace installation from backup, you will
need to restore:

  * Your database (either the demo database or MySQL)
  * The search indexes and related indexer files

Of the two, the database backup is the most crucial--search indexes
are worth restoring if you have backups, but they can be recreated
from scratch if necessary.


### Recovering your database

If you are using MySQL, recovering your database just requires loading
your `mysqldump` backup into an empty database.  If you are using the
`scripts/backup.sh` script (described above), this dump file is named
`mysqldump.sql` in your backup `.zip` file.

To load a MySQL dump file, follow the directions in *Set up your MySQL
database* to create an empty database with the appropriate
permissions.  Then, populate the database from your backup file using
the MySQL client:

    mysql -uarchivesspace -p < mysqldump.sql
    
(change the username as required and enter your password when
prompted).


If you are using the demo database, your backup `.zip` file will
contain a directory called `demo_db_backups`.  Each subdirectory of
`demo_db_backups` contains a backup of the demo database.  To
restore from a backup, copy its `archivesspace_demo_db` directory back
to your ArchivesSpace data directory.  For example:

     cp -a /unpacked/zip/demo_db_backups/demo_db_backup_1373323208_25926/archivesspace_demo_db \
           /path/to/archivesspace/data/



### Recovering the search indexes and related indexer files

This step is optional since indexes can be rebuilt from the contents
of the database.  However, recovering your search indexes can reduce
the time needed to get your system running again.

The backup `.zip` file contains two directories used by the
ArchivesSpace indexer:

  * solr.backup-[timestamp]/snapshot.[timestamp] -- a snapshot of the
    index files.
  * solr.backup-[timestamp]/indexer_state -- the files used by the
    indexer to remember what it last indexed.

To restore these directories from backup:

  * Copy your index snapshot to `/path/to/archivesspace/data/solr_index/index`
  * Copy your indexer_state backup to `/path/to/archivesspace/data/indexer_state`

For example:

     mkdir -p /path/to/archivesspace/data/solr_index

     cp -a /unpacked/zip/solr.backup-26475-1373323208/snapshot.20130709084008464 \ 
           /path/to/archivesspace/data/solr_index/index

     cp -a /unpacked/zip/solr.backup-26475-1373323208/indexer_state \ 
           /path/to/archivesspace/data/


### Checking your search indexes

ArchivesSpace ships with a script that can run Lucene's CheckIndex
tool for you, verifying that a given Solr index is free from
corruption.  To test an index, run the following command from your
`archivesspace` directory:

     # Or scripts/checkindex.bat for Windows
     scripts/checkindex.sh data/solr_index/index

You can use the same script to check that your Solr backups are valid:

     scripts/checkindex.sh /unpacked/zip/solr.backup-26475-1373323208/snapshot.20130709084008464


