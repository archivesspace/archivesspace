Running ArchivesSpace with load balancing and multiple tenants
==============================================================

This document describes two aspects of running ArchivesSpace in a
clustered environment: for load-balancing purposes, and for supporting
multiple tenants (isolated installations of the system in a common
deployment environment).

The configuration described in this document is one possible approach,
but it is not intended to be prescriptive: the application layer of
ArchivesSpace is stateless, so any mechanism you prefer for load
balancing across web applications should work just as well as the one
described here.

Unless otherwise stated, it is assumed that you have root access on
your machines, and all commands are to be run as root (or with sudo).


# Architecture overview

![Overview](docs/images/overview.png)

This document assumes an architecture with the following components:

  * A load balancer machine running the Nginx web server
  
  * Two application servers, each running a full ArchivesSpace
    application stack

  * A MySQL server
  
  * A shared NFS volume mounted under `/aspace` on each machine
  

# Overview of files

The `files` directory in this repository (in the same directory as this
`README.md`) contains what will become the contents of the `/aspace`
directory, shared by all servers.  It has the following layout:

     /aspace
     ├── archivesspace
     │   ├── config
     │   │   ├── config.rb
     │   │   └── tenant.rb
     │   ├── software
     │   └── tenants
     │       └── _template
     │           └── archivesspace
     │               ├── config
     │               │   ├── config.rb
     │               │   └── instance_hostname.rb.example
     │               └── init_tenant.sh
     └── nginx
         └── conf
             ├── common
             │   └── server.conf
             └── tenants
                 └── _template.conf.example


The highlights:

  * `/aspace/archivesspace/config/config.rb` -- A global configuration file for all ArchivesSpace instances.  Any configuration options added to this file will be applied to all tenants on all machines.
    
  * `/aspace/archivesspace/software/` -- This directory will hold the master copies of the `archivesspace.zip` distribution.  Each tenant will reference one of the versions of the ArchivesSpace software in this directory.

  * `/aspace/archivesspace/tenants/` -- Each tenant will have a sub-directory under here, based on the `_template` directory provided.  This holds the configuration files for each tenant.
    
  * `/aspace/archivesspace/tenants/[tenant name]/config/config.rb` -- The global configuration file for [tenant name].  This contains tenant-specific options that should apply to all of the tenant's ArchivesSpace instances (such as their database connection settings).
    
  * `/aspace/archivesspace/tenants/[tenant name]/config/instance_[hostname].rb` -- The configuration file for a tenant's ArchivesSpace instance running on a particular machine.  This allows configuration options to be set on a per-machine basis (for example, setting different ports for different application servers)
    
  * `/aspace/nginx/conf/common/server.conf` -- Global Nginx configuration settings (applying to all tenants)
    
  * `/aspace/nginx/conf/tenants/[tenant name].conf` -- A tenant-specific Nginx configuration file.  Used to set the URLs of each tenant's ArchivesSpace instances.


# Getting started

We'll assume you already have the following ready to go:

  * Three newly installed machines, each running RedHat (or CentOS)
    Linux (we'll refer to these as `loadbalancer`, `apps1` and
    `apps2`).
    
  * A MySQL server.
  
  * An NFS volume that has been mounted as `/aspace` on each machine.
    All machines should have full read/write access to this area.
  
  * An area under `/aspace.local` which will store instance-specific
    files (such as log files and Solr indexes).  Ideally this is just
    a directory on local disk.

  * Java 1.6 (or above) installed on each machine.


## Populate your /aspace/ directory

Start by copying the directory structure from `files/` into your
`/aspace` volume.  This will contain all of the configuration files
shared between servers:

     mkdir /var/tmp/aspace/
     cd /var/tmp/aspace/
     unzip -x /path/to/archivesspace.zip
     cp -av archivesspace/clustering/files/* /aspace/

You can do this on any machine that has access to the shared
`/aspace/` volume.


## Install the cluster init script

On your application servers (`apps1` and `apps2`) you will need to
install the supplied init script:

     cp -a /aspace/aspace-cluster.init /etc/init.d/aspace-cluster
     chkconfig --add aspace-cluster

This will start all configured instances when the system boots up, and
can also be used to start/stop individual instances.


## Install and configure Nginx

You will need to install Nginx on your `loadbalancer` machine, which
you can do by following the directions at
http://nginx.org/en/download.html.  Using the pre-built packages for
your platform is fine.  At the time of writing, the process for CentOS
is simply:

     wget http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
     rpm -i nginx-release-centos-6-0.el6.ngx.noarch.rpm
     yum install nginx

Nginx will place its configuration files under `/etc/nginx/`.  For
now, the only change we need to make is to configure Nginx to load our
tenants' configuration files.  To do this, edit
`/etc/nginx/conf.d/default.conf` and add the line:

     include /aspace/nginx/conf/tenants/*.conf;

*Note:* the location of Nginx's main config file might vary between
systems.  Another likely candidate is `/etc/nginx/nginx.conf`.


## Download the ArchivesSpace distribution

Rather than having every tenant maintain their own copy of the
ArchivesSpace software, we put a shared copy under
`/aspace/archivesspace/software/` and have each tenant instance refer
to that copy.  To set this up, run the following commands on any one
of the servers:

     cd /aspace/archivesspace/software/
     unzip -x /path/to/downloaded/archivesspace-x.y.z.zip
     mv archivesspace archivesspace-x.y.z
     ln -s archivesspace-x.y.z stable

Note that we unpack the distribution into a directory containing its
version number, and then assign that version the symbolic name
"stable".  This gives us a convenient way of referring to particular
versions of the software, and we'll use this later on when setting up
our tenant.

We'll be using MySQL, which means we must make the MySQL connector
library available.  To do this, place it in the `lib/` directory of
the ArchivesSpace package:

     cd /aspace/archivesspace/software/stable/lib
     wget http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.24/mysql-connector-java-5.1.24.jar


# Defining a new tenant

With our server setup out of the way, we're ready to define our first
tenant.  As shown in *Overview of files* above, each tenant has their
own directory under `/aspace/archivesspace/tenants/` that holds all of
their configuration files.  In defining our new tenant, we will:

  * Create a Unix account for the tenant

  * Create a database for the tenant

  * Create a new set of ArchivesSpace configuration files for the
    tenant

  * Set up the database

Our newly defined tenant won't initially have any ArchivesSpace
instances, but we'll set those up afterwards.

To complete the remainder of this process, there are a few bits of
information you will need.  In particular, you will need to know:

  * The identifier you will use for the tenant you will be creating.
    In this example we use `exampletenant`.

  * Which port numbers you will use for the application's backend,
    Solr instance, staff and public interfaces.  These must be free on
    your application servers.

  * If running each tenant under a separate Unix account, the UID and
    GID you'll use for them (which must be free on each of your
    servers).

  * The public-facing URLs for the new tenant.  We'll use
    `staff.example.com` for the staff interface, and `public.example.com`
    for the public interface.


## Creating a Unix account

Although not strictly required, for security and ease of system
monitoring it's a good idea to have each tenant instance running under
a dedicated Unix account.

We will call our new tenant `exampletenant`, so let's create a user
and group for them now.  You will need to run these commands on *both*
application servers (`apps1` and `apps2`):

     groupadd --gid 2000 exampletenant
     useradd --uid 2000 --gid 2000 exampletenant

Note that we specify a UID and GID explicitly to ensure they match
across machines.


## Creating the database

ArchivesSpace assumes that each tenant will have their own MySQL
database.  You can create this from the MySQL shell:

     create database exampletenant default character set utf8;
     grant all on exampletenant.* to 'example'@'%' identified by 'example123';

In this example, we have a MySQL database called `exampletenant`, and
we grant full access to the user `example` with password `example123`.
Assuming our database server is `db.example.com`, this corresponds to
the database URL:

     jdbc:mysql://db.example.com:3306/exampletenant?user=example&password=example123&useUnicode=true&characterEncoding=UTF-8

We'll make use of this URL in the following section.


## Creating the tenant configuration

Each tenant has their own set of files under the
`/aspace/archivesspace/tenants/` directory.  We'll define our new
tenant (called `exampletenant`) by copying the template set of
configurations and running the `init_tenant.sh` script to set them
up.  We can do this on either `apps1` or `apps2`--it only needs to be
done once:

     cd /aspace/archivesspace/tenants
     cp -a _template exampletenant

Note that we've named the tenant `exampletenant` to match the Unix
account it will run as.  Later on, the startup script will use this
fact to run each instance as the correct user.

For now, we'll just edit the configuration file for this tenant, under
`exampletenant/archivesspace/config/config.rb`.  When you open this file you'll see two
placeholders that need filling in: one for your database URL, which in
our case is just:

     jdbc:mysql://db.example.com:3306/exampletenant?user=example&password=example123&useUnicode=true&characterEncoding=UTF-8

and the other for this tenant's search, staff and public user secrets,
which should be random, hard to guess passwords.



# Adding the tenant instances

To add our tenant instances, we just need to initialize them on each
of our servers.  On `apps1` *and* `apps2`, we run:

     cd /aspace/archivesspace/tenants/exampletenant/archivesspace
     ./init_tenant.sh stable

If you list the directory now, you will see that the `init_tenant.sh`
script has created a number of symlinks.  Most of these refer back to
the `stable` version of the ArchivesSpace software we unpacked
previously, and some contain references to the `data` and `logs`
directories stored under `/aspace.local`.

Each server has its own configuration file that tells the
ArchivesSpace application which ports to listen on.  To set this up,
make two copies of the example configuration by running the following
command on `apps1` then `apps2`:

     cd /aspace/archivesspace/tenants/exampletenant/archivesspace
     cp config/instance_hostname.rb.example config/instance_`hostname`.rb

Then edit each file to set the URLs that the instance will use.
Here's our `config/instance_apps1.example.com.rb`:

     {
       :backend_url => "http://apps1.example.com:8089",
       :frontend_url => "http://apps1.example.com:8080",
       :solr_url => "http://apps1.example.com:8090",
       :indexer_url => "http://apps1.example.com:8091",
       :public_url => "http://apps1.example.com:8081",
     }

Note that the filename is important here: it must be:

     instance_[server hostname].rb

These URLs will determine which ports the application listens on when
it starts up, and are also used by the ArchivesSpace indexing system
to track updates across the cluster.


## Starting up

As a one-off, we need to populate this tenant's database with the
default set of tables.  You can do this by running the
`setup-database.sh` script on either `apps1` or `apps2`:

     cd /aspace/archivesspace/tenants/exampletenant/archivesspace
     scripts/setup-database.sh

With the two instances configured, you can now use the init script to
start them up on each server:

     /etc/init.d/aspace-cluster start-tenant exampletenant

and you can monitor each instance's log file under
`/aspace.local/tenants/exampletenant/logs/`.  Once they're started,
you should be able to connect to each instance with your web browser
at the configured URLs.


# Configuring the load balancer

Our final step is configuring Nginx to accept requests for our staff
and public interfaces and forward them to the appropriate application
instance.  Working on the `loadbalancer` machine, we create a new
configuration file for our tenant:

     cd /aspace/nginx/conf/tenants
     cp -a _template.conf.example exampletenant.conf
     
Now open `/aspace/nginx/conf/tenants/exampletenant.conf` in an
editor.  You will need to:

  * Replace `<tenantname>` with `exampletenant` where it appears.
  
  * Change the `server` URLs to match the hostnames and ports you
    configured each instance with.

  * Insert the tenant's hostnames for each `server_name` entry.  In
    our case these are `public.example.com` for the public interface, and
    `staff.example.com` for the staff interface.

Once you've saved your configuration, you can test it with:

     /usr/sbin/nginx -t

If Nginx reports that all is well, reload the configurations with:

     /usr/sbin/nginx -s reload

And, finally, browse to `http://public.example.com/` to verify that Nginx
is now accepting requests and forwarding them to your app servers.
We're done!
