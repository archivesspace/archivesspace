# Getting started

If you have the Java 1.6.0 SDK (or above) you can build and run a demo
server with the following commands:

     git clone git://github.com/hudmol/archivesspace.git

     cd archivesspace

     build/run dist

     java -XX:MaxPermSize=256m -Xmx256m -Dfile.encoding=UTF-8 -jar archivesspace.jar

This will start the ArchivesSpace application running on:

  http://localhost:8080/

and the backend web service running on:

  http://localhost:8089/

If you'd like to use different ports, you can run:

    java -XX:MaxPermSize=256m -Xmx256m -Dfile.encoding=UTF-8 -jar archivesspace.jar [frontend port] [backend port]

To set up the application, browse to http://localhost:8080/ and log in
using the adminstrator account:

* Username: `admin`
* Password: `admin`

Once logged in, you can create a new repository by selecting "Create a
repository" from the drop-down menu at the top right hand side of the
screen.  Once you have created a repository, you can log out and
register new user accounts from the link in the log-in form.

Note: If you have already run the service in demo mode, you may need
to remove the existing demo database in order to avoid a
'java.sql.SQLException: Failed to create database' error:

		build/run db:nuke


## Running ArchivesSpace with a custom configuration file

ArchivesSpace loads its configuration from a `config.rb` file, and
will look for this file in several locations:

  * If you're running the `archivesspace.jar` as above, it will
    attempt to load the configuration from the current user's home
    directory: `$HOME/.aspace_config.rb` 

  * If you're running ArchivesSpace under Tomcat, it will attempt to
    load `$TOMCAT_HOME/conf/config.rb`

  * If you're running in development mode, it will attempt to load
    `/path/to/archivesspace/config/config.rb` 

To explicitly specify the location of your configuration file, you can
run the application with the 'aspace.config' system property set.  For
example:

     java -XX:MaxPermSize=256m -Xmx256m -Dfile.encoding=UTF-8 -Daspace.config=/path/to/my/config.rb -jar archivesspace.jar

You can also override individual configuration options by setting the
corresponding system property.  The command line:

     java -XX:MaxPermSize=256m -Xmx256m -Dfile.encoding=UTF-8 -Daspace.config.data_directory=/path/to/my/data -jar archivesspace.jar

is equivalent to adding a `config.rb` entry like:

     AppConfig[:data_directory] = "/path/to/my/data"


## Configuring LDAP authentication

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


# Further documentation

Latest documentation is published at [http://hudmol.github.com/archivesspace/](http://hudmol.github.com/archivesspace/)
