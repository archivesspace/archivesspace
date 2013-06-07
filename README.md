ArchivesSpace README
--------------------
<http://archivesspace.org>

# Getting started

The quickest way to get ArchivesSpace up and running is to download
the latest distribution .zip file from the following URL:

  https://github.com/archivesspace/archivesspace/wiki/Downloads

You will need to have Java 1.6 (or newer) installed on your machine,
but everything else you need is included in the .zip file.  You can
check your Java version by running the command:

     java -version

When you extract the .zip file, it will create a directory called
`archivesspace`.  To run the system, just execute the appropriate
startup script for your platform.  On Linux and OSX:

     cd /path/to/archivesspace
     ./archivesspace.sh

and for Windows:

     cd \path\to\archivesspace
     archivesspace.bat

the system will log to the console as it starts up, and after a minute
or so, you should be able to point your browser to
http://localhost:8080/ and access the ArchivesSpace application.


# First steps

To start using the application, log in using the adminstrator account:

* Username: `admin`
* Password: `admin`

Once logged in, you can create a new repository by selecting "Create a
repository" from the drop-down menu at the top right hand side of the
screen.  Once you have created a repository, you can log out and
register new user accounts from the link in the log-in form.


# Running ArchivesSpace with a custom configuration file

Under your `archivesspace` directory you will see a directory called
`config` which contains a file called `config.rb`.  By modifying this
file, you can override the defaults that ArchivesSpace ships with:
changing things like the ports it listens on and where it puts its data.


# Running ArchivesSpace against MySQL

The ArchivesSpace distribution runs against an embedded database by
default, but it's a good idea to run against MySQL for production
use.

## Download MySQL Connector

ArchivesSpace requires the
[MySQL Connector for Java](http://dev.mysql.com/downloads/connector/j/),
which must be downloaded separately because of its licensing agreement.
Download the Connector and place it in a location where ArchivesSpace can
find it on its classpath:

         $ curl -Oq http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.24/mysql-connector-java-5.1.24.jar

         $ mv mysql-connector-java-5.1.24.jar lib

## Set up MySQL database

Next, create an empty database in MySQL and grant access
to a dedicated ArchivesSpace user (this example uses username `as` and
password `as123`):

         $ mysql -uroot -p

         mysql> create database archivesspace default character set utf8;
         Query OK, 1 row affected (0.08 sec)

         mysql> grant all on archivesspace.* to 'as'@'localhost' identified by 'as123';
         Query OK, 0 rows affected (0.21 sec)

Then, modify your `config/config.rb` file to refer to your MySQL
database:

     AppConfig[:db_url] = "jdbc:mysql://localhost:3306/archivesspace?user=as&password=as123&useUnicode=true&characterEncoding=UTF-8"

There is a database setup script that will create all the tables that
ArchivesSpace requires.  Run this with:

    scripts/setup-database.sh  # or setup-database.bat under Windows

## Start ArchivesSpace

Once your database is configured, start the application using
`archivesspace.sh` (or `archivesspace.bat` under Windows).


# Configuring LDAP authentication

ArchivesSpace can be configured to authenticate against one or more
LDAP directories by specifying them in the application's configuration
file.  When a user logs in, each authentication source is tried in
order until one matches or all sources are exhausted.

Here's a minimal example of LDAP authentication:

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
Each directory under the `plugins` directory contains a plug-in. In the standard
distribution there are two plug-in directories - `hello_world` and `local`.
The `hello_world` directory contains a simple exemplar plug-in. The `local` directory
is empty - this is a place to put any local customizations or extensions to ArchivesSpace
without having to change the core codebase.

Plug-ins are enabled by listing them in the configuration file. You will see the following line in
`common/config/config-defaults.rb`:

    AppConfig[:plugins] = ['local']

This states that by default the `local` plug-in is enabled and any files contained there will be
loaded and available to the application. In order to enable other plug-ins simply override this
configuration in `common/config/config.rb`. For example, to enable the `hello_world` plug-in,
add a line like this:

    AppConfig[:plugins] = ['local', 'hello_world']

Note that the string must be identical to the name of the directory under the `plugins` directory.
Also note that the ordering of plug-ins in the list determines the order that the plug-ins will
be loaded.

For more information about plug-ins and how to use them to override and customize ArchivesSpace,
please see the README in the `plugins` directory.


# Creating backups

## Using the provided script

ArchivesSpace provides some simple scripts for backing up a single
instance to a `.zip` file.  You can run:

     scripts/backup.sh --output /path/to/backup-yyyymmdd.zip

and the script will generate a file containing:

  * A snapshot of the Solr index and related indexer files
  * A snapshot of the demo database (if you're using the demo
    database)

If you're running against MySQL and have `mysqldump` installed, you
can also provide the `--mysqldump` option.  This will read the
database settings from your configuration file and add a dump of your
database to the resulting `.zip` file.


## Managing your own backups

If you want more control over your backups, there's nothing stopping
you from developing your own scripts.  ArchivesSpace stores all
persistent data in the database, so as long as you have backups of
your database then you can always recover.

If you're running MySQL, the `mysqldump` utility can dump the database
schema and data to a file.  It's a good idea to run this with the
`--single-transaction` option to avoid locking your database tables
while your backups run.

If you're running with the demo database, you can create periodic
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


# Further documentation

Additional deployment documentation can be found on the ArchivesSpace
wiki at [https://github.com/archivesspace/archivesspace/wiki](https://github.com/archivesspace/archivesspace/wiki).

The latest technical documentation, including API documentation and
architecture notes, is published at
[http://hudmol.github.io/archivesspace/doc](http://hudmol.github.com/archivesspace/doc/).

# License

ArchivesSpace is released under the [Educational Community License,
version 2.0](http://opensource.org/licenses/ecl2.php). See the
[COPYING](COPYING) file for more information.
