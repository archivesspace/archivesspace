ArchivesSpace README
--------------------

[![Build Status](https://travis-ci.org/archivesspace/archivesspace.svg)](https://travis-ci.org/archivesspace/archivesspace.svg)[![Code Climate](https://codeclimate.com/github/archivesspace/archivesspace.png)](https://codeclimate.com/github/archivesspace/archivesspace)


<http://archivesspace.org>
[Wiki and Issue Tracker](https://archivesspace.atlassian.net)
IRC: #archivesspace ( chat.freenode.net )

# System requirements

* Java 1.6 or higher; Java 1.7 or 1.8 recommended.
* At least 1024 MB RAM allocated to the application
* A [supported browser](https://archivesspace.atlassian.net/wiki/display/ADC/Supported+Browsers)

ArchivesSpace has been tested on Linux (Red Hat and Ubuntu), Mac OS X, and
Windows (XP, Windows 7, Windows 8, Windows Server 2008 & 2012 ).

MySQL is not required, but is **strongly** recommended for production use.

**The embedded database is for testing purposes only. You should use MySQL for
any data intended for production, including data in a test instance that you
intend to move over to a production instance.**

# Getting started

The quickest way to get ArchivesSpace up and running is to download
the latest distribution `.zip` file from the following URL:

  https://github.com/archivesspace/archivesspace/releases

You will need to have Java 1.6 (or newer) installed on your machine.
You can check your Java version by running the command:

     java -version

Currently, if you want to use Java 1.8, you will need to remove the
jdt-compiler jar library from the java classpath ( lib directory of
your ArchivesSpace directory). This will disable the use of Jasper
reports ( but not regular reports).  

When you extract the `.zip` file, it will create a directory called
`archivesspace`.  To run the system, just execute the appropriate
startup script for your platform.  On Linux and OSX:

     cd /path/to/archivesspace
     ./archivesspace.sh

and for Windows:

     cd \path\to\archivesspace
     archivesspace.bat

This will start ArchivesSpace running in foreground mode (so it will
shut down when you close your terminal window).  Log output will be
written to the file `logs/archivesspace.out` (by default).

**Note:** If you're running Windows and you get an error message like
`unable to resolve type 'size_t'` or `no such file to load -- bundler`,
make sure that there are no spaces in any part of the path name in which the
ArchivesSpace directory is located.

## Start ArchivesSpace

The first time it starts, the system will take a minute or so to start
up.  Once it is ready, confirm that ArchivesSpace is running correctly by 
accessing the following URLs in your browser:

  - http://localhost:8089/ -- the backend
  - http://localhost:8080/ -- the staff interface
  - http://localhost:8081/ -- the public interface
  - http://localhost:8090/ -- the Solr admin console
  - http://localhost:8888/archivesspace -- documentation

To start using the Staff interface application, log in using the adminstrator 
account:

* Username: `admin`
* Password: `admin`

Then, you can create a new repository by selecting "System" -> "Manage
repositories" at the top right hand side of the screen.  From the
"System" menu, you can perform a variety of administrative tasks, such
as creating and modifying user accounts.  **Be sure to change the
"admin" user's password at this time.**

# Configuring ArchivesSpace

The primary configuration for ArchivesSpace is done in the config/config.rb
file. By default, this file contains the default settings, which are indicated
by commented out lines ( indicated by the "#" in the file ). You can adjust these 
settings by adding new lines that change the default and restarting 
ArchivesSpace. Be sure that your new settings are not commented out 
( i.e. do NOT start with a "#" ), otherwise the settings will not take effect. 

# Running ArchivesSpace as a Unix daemon

The `archivesspace.sh` startup script doubles as an init script.  If
you run:

     archivesspace.sh start

ArchivesSpace will run in the background as a daemon (logging to
`logs/archivesspace.out` by default, as before).  You can shut it down with:

     archivesspace.sh stop

You can even install it as a system-wide init script by creating a
symbolic link:

     cd /etc/init.d
     ln -s /path/to/your/archivesspace/archivesspace.sh archivesspace

Then use the appropriate tool for your distribution to set up the
run-level symbolic links (such as `chkconfig` for RedHat or
`update-rc.d` for Debian-based distributions).

Note that you may want to edit archivesspace.sh to set the account
that the system runs under, JVM options, and so on.

# Running ArchivesSpace as a Windows Service

Running ArchivesSpace as a Windows service requires some additional 
configuration. 

You can also use Apache [procrun]((http://commons.apache.org/proper/commons-daemon/procrun.html) to configure ArchivesSpace. We have 
provided a service.bat script that will attempt to configure 
procrun for you (under `launcher\service.bat`). 

To run this script, first you need to [download procrun](http://www.apache.org/dist/commons/daemon/binaries/windows/ ).
Extract the files and copy the prunsrv.exe and prunmgr.exe to your
ArchivesSpace directory. 

You also need to be sure that Java in your system path and also to set `JAVA_HOME` as a global environment variable. 
To add Java to your path, edit you %PATH% environment variable to include the directory of
your java executable ( it will be something like `C:\Program Files
(x86)\Java\bin` ). To add `JAVA_HOME`, add a new system variable and put the
directory where java was installed ( something like `C:\Program Files
(x86)\Java` ).

Before setting up the ArchivesSpace service, you should also [configure
ArchivesSpace to run against MySQL](https://github.com/archivesspace/archivesspace#running-archivesspace-against-mysql).
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

# Running ArchivesSpace with a custom configuration file

Under your `archivesspace` directory you will see a directory called
`config` which contains a file called `config.rb`.  By modifying this
file, you can override the defaults that ArchivesSpace ships with:
changing things like the ports it listens on and where it puts its data.


# Running ArchivesSpace against MySQL

Out of the box, the ArchivesSpace distribution runs against an
embedded database, but this is only suitable for demonstration
purposes.  When you are ready to starting using ArchivesSpace with
real users and data, you should switch to using MySQL.  MySQL offers
significantly better performance when multiple people are using the
system, and will ensure that your data is kept safe.


## Download MySQL Connector

ArchivesSpace requires the
[MySQL Connector for Java](http://dev.mysql.com/downloads/connector/j/),
which must be downloaded separately because of its licensing agreement.
Download the Connector and place it in a location where ArchivesSpace can
find it on its classpath:

         $ cd lib
         $ curl -Oq http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.34/mysql-connector-java-5.1.34.jar 

Note that the version of the MySQL connector may be different by the
time you read this.


## Set up your MySQL database

Next, create an empty database in MySQL and grant access to a dedicated
ArchivesSpace user. The following example uses username `as`
and password `as123`.

**NOTE: WHEN CREATING THE DATABASE, YOU MUST SET THE DEFAULT CHARACTER
ENCODING FOR THE DATABASE TO BE `utf8`.** This is particularly important
if you use a MySQL client to create the database (e.g. Navicat, MySQL
Workbench, phpMyAdmin, etc.).

         $ mysql -uroot -p

         mysql> create database archivesspace default character set utf8;
         Query OK, 1 row affected (0.08 sec)

         mysql> grant all on archivesspace.* to 'as'@'localhost' identified by 'as123';
         Query OK, 0 rows affected (0.21 sec)

Then, modify your `config/config.rb` file to refer to your MySQL
database. When you modify your configuration file, **MAKE SURE THAT YOU
SPECIFY THAT THE CHARACTER ENCODING FOR THE DATABASE TO BE `UTF-8`** as shown
below:

     AppConfig[:db_url] = "jdbc:mysql://localhost:3306/archivesspace?user=as&password=as123&useUnicode=true&characterEncoding=UTF-8"

There is a database setup script that will create all the tables that
ArchivesSpace requires.  Run this with:

    scripts/setup-database.sh  # or setup-database.bat under Windows

You can now follow the instructions in the "Getting Started" section to start
your ArchivesSpace application. 


# Backup and recovery

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


# Re-creating indexes

ArchivesSpace keeps track of what has been indexed by using the files
under `data/indexer_state`.  If these files are missing, the indexer
assumes that nothing has been indexed and reindexes everything.

To force ArchivesSpace to reindex all records, just delete the
directory `/path/to/archivesspace/data/indexer_state`.  Since the
indexing process is cumulative, there's no harm in indexing the same
document multiple times.


# Resetting passwords

Under the `scripts` directory you will find a script that lets you
reset a user's password.  You can invoke it as:

    scripts/password-reset.sh theusername newpassword  # or password-reset.bat under Windows

If you are running against MySQL, you can use this command to set a
password while the system is running.  If you are running against the
demo database, you will need to shutdown ArchivesSpace before running
this script.


# Configuring LDAP authentication

ArchivesSpace can manage its own user directory, but can also be
configured to authenticate against one or more LDAP directories by
specifying them in the application's configuration file.  When a user
attempts to log in, each authentication source is tried until one
matches.

Here is a minimal example of an LDAP configuration:

     AppConfig[:authentication_sources] = [{
                                             :model => 'LDAPAuth',
                                             :hostname => 'ldap.example.com',
                                             :port => 389,
                                             :base_dn => 'ou=people,dc=example,dc=com',
                                             :username_attribute => 'uid',
                                             :attribute_map => {:cn => :name},
     }]

With this configuration, ArchivesSpace performs authentication by
connecting to `ldap://ldap.example.com:389/`, binding anonymously,
searching the `ou=people,dc=example,dc=com` tree for `uid = <username>`. 

If the user is found, ArchivesSpace authenticates them by
binding using the password specified.  Finally, the `:attribute_map`
entry specifies how LDAP attributes should be mapped to ArchivesSpace
user attributes (mapping LDAP's `cn` to ArchivesSpace's `name` in the
above example).

Many LDAP directories don't support anonymous binding.  To integrate
with such a directory, you will need to specify the username and
password of a user with permission to connect to the directory and
search for other users.  Modifying the previous example for this case
looks like this:


     AppConfig[:authentication_sources] = [{
                                             :model => 'LDAPAuth',
                                             :hostname => 'ldap.example.com',
                                             :port => 389,
                                             :base_dn => 'ou=people,dc=example,dc=com',
                                             :username_attribute => 'uid',
                                             :attribute_map => {:cn => :name},
                                             :bind_dn => 'uid=archivesspace_auth,ou=system,dc=example,dc=com',
                                             :bind_password => 'secretsquirrel',
     }]


Finally, some LDAP directories enforce the use of SSL encryption.  To
configure ArchivesSpace to connect via LDAPS, change the port as
appropriate and specify the `encryption` option:

     AppConfig[:authentication_sources] = [{
                                             :model => 'LDAPAuth',
                                             :hostname => 'ldap.example.com',
                                             :port => 636,
                                             :base_dn => 'ou=people,dc=example,dc=com',
                                             :username_attribute => 'uid',
                                             :attribute_map => {:cn => :name},
                                             :bind_dn => 'uid=archivesspace_auth,ou=system,dc=example,dc=com',
                                             :bind_password => 'secretsquirrel',
                                             :encryption => :simple_tls,
     }]


# Plug-ins and local customizations

Under your `archivesspace` directory there is a directory called `plugins`.
Each directory under the `plugins` directory contains a plug-in. In the
standard distribution there are several plug-in directories, including
`hello_world` and `local`. The `hello_world` directory contains a simple
exemplar plug-in. The `local` directory is empty - this is a place to put
any local customizations or extensions to ArchivesSpace without having to
change the core codebase.

Plug-ins are enabled by listing them in the configuration file. You will see the following line in
`config/config.rb`:

     # AppConfig[:plugins] = ['local']

This states that by default the `local` plug-in is enabled and any files
contained there will be loaded and available to the application. In order
to enable other plug-ins simply override this configuration in
`config/config.rb`. For example, to enable the `hello_world` plug-in, add
a line like this (ensuring you remove the `#` at the beginning of the line):

    AppConfig[:plugins] = ['local', 'hello_world']

Note that the string must be identical to the name of the directory under the
`plugins` directory. Also note that the ordering of plug-ins in the list
determines the order that the plug-ins will be loaded.

For more information about plug-ins and how to use them to override and
customize ArchivesSpace, please see the README in the `plugins` directory.


# Running ArchivesSpace with an external Solr instance

[Instructions for using an external Solr server](https://github.com/archivesspace/archivesspace/blob/master/README_SOLR.md)

# Running ArchivesSpace under a prefix

[Instructions for running under a prefix](https://github.com/archivesspace/archivesspace/blob/master/README_PREFIX.md).

# Upgrading ArchivesSpace

[Upgrading to a new release of ArchivesSpace](https://github.com/archivesspace/archivesspace/blob/master/UPGRADING.md)


# Monitoring with New Relic

[Configuring ArchivesSpace to integrate with New Relic](https://github.com/archivesspace/archivesspace/blob/master/plugins/newrelic/README_NEWRELIC.md)

# Further documentation

Additional documentation can be found on the ArchivesSpace
wiki at [https://archivesspace.atlassian.net/wiki/display/ADC](https://archivesspace.atlassian.net/wiki/display/ADC).

A document describing the architecture of ArchivesSpace is published
at [https://github.com/archivesspace/archivesspace/blob/master/ARCHITECTURE.md](https://github.com/archivesspace/archivesspace/blob/master/ARCHITECTURE.md).

The latest technical documentation, including API documentation and
architecture notes, is published at
[http://archivesspace.github.io/archivesspace/doc](http://archivesspace.github.com/archivesspace/doc/).

# Contributing

Contributors are welcome! Please read about our [Contributor License Agreement](https://github.com/archivesspace/archivesspace/tree/master/contributing) for more information. 

# License

ArchivesSpace is released under the [Educational Community License,
version 2.0](http://opensource.org/licenses/ecl2.php). See the
[COPYING](COPYING) file for more information.


# Credits

ArchivesSpace 1.0 has been developed by [Hudson Molonglo](http://www.hudsonmolonglo.com)
in partnership with the New York University Libraries, UC San Diego
Libraries, and University of Illinois Urbana-Champaign Library and with
funding from the Andrew W. Mellon Foundation, organizational support from
LYRASIS, and contributions from diverse persons in the archives community.
