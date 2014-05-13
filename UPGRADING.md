# Upgrading to a new release of ArchivesSpace

## Create a backup of your ArchivesSpace instance

You should make sure you have a working backup of your ArchivesSpace
installation before attempting an upgrade.  Follow the steps
under the *Backup and recovery* section in [README.md](https://github.com/archivesspace/archivesspace/blob/master/README.md) to do this.


## Unpack the new version

It's a good idea to unpack a fresh copy of the version of
ArchivesSpace you are upgrading to.  This will ensure that you are
running the latest versions of all files.  For example, on Mac OS X or
Linux:

     $ mkdir archivesspace-1.0.9
     $ cd archivesspace-1.0.9
     $ unzip -x archivesspace-v1.0.9.zip

On Windows, you can do the same by extracting ArchivesSpace into a new
folder you create in Windows Explorer.

## Shut down your ArchivesSpace instance

To ensure you get a consistent copy, you will need to shut down your
running ArchivesSpace instance now.


## Copy your configuration and data files

You will need to bring across the following files and directories from
your original ArchivesSpace installation:

  * the `data` directory

  * the `config` directory

  * your `lib/mysql-connector*.jar` file (if using MySQL)

  * any plugins and local modifications you have installed in your `plugins` directory

For example, on Mac OS X or Linux:

     $ cd archivesspace-1.0.9/archivesspace
     $ cp -a /path/to/archivesspace-1.0.7.1/archivesspace/data/* data/
     $ cp -a /path/to/archivesspace-1.0.7.1/archivesspace/config/* config/
     $ cp -a /path/to/archivesspace-1.0.7.1/archivesspace/lib/mysql-connector* lib/
     $ cp -a /path/to/archivesspace-1.0.7.1/archivesspace/plugins/local plugins/
     $ cp -a /path/to/archivesspace-1.0.7.1/archivesspace/plugins/wonderful_plugin plugins/

Or on Windows:

     $ cd archivesspace-1.0.9\archivesspace
     $ xcopy \path\to\archivesspace-1.0.7.1\archivesspace\data\* data /i /k /h /s /e /o /x /y
     $ xcopy \path\to\archivesspace-1.0.7.1\archivesspace\config\* config /i /k /h /s /e /o /x /y
     $ xcopy \path\to\archivesspace-1.0.7.1\archivesspace\lib\mysql-connector* lib /i /k /h /s /e /o /x /y
     $ xcopy \path\to\archivesspace-1.0.7.1\archivesspace\plugins\local plugins\local /i /k /h /s /e /o /x /y
     $ xcopy \path\to\archivesspace-1.0.7.1\archivesspace\plugins\wonderful_plugin plugins\wonderful_plugin /i /k /h /s /e /o /x /y


Note that you may want to preserve the logs file (`logs/archivesspace.out` 
by default) from your previous installation--just in case you need to 
refer to it later.


## Run the database migrations

With everything copied, the final step is to run the database
migrations.  This will apply any schema changes and data migrations
that need to happen as a part of the upgrade.  To do this, use the
`setup-database` script for your platform. For example, on Mac OS X
or Linux:

     $ cd archivesspace-1.0.9/archivesspace
     $ scripts/setup-database.sh

Or on Windows:

     $ cd archivesspace-1.0.9\archivesspace
     $ scripts\setup-database.bat

## That's it!

You can now start your new ArchivesSpace version as normal.
