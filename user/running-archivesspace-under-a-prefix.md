---
title: Running ArchivesSpace under a prefix 
layout: en
permalink: /user/running-archivesspace-under-a-prefix/ 
---
------------------------------------

This document describes a simple approach for those wishing to deviate from the recommended
practive of running each user-facing ArchivesSpace application on its own subdomain, and instead
serve each application under a prefix, e.g.

    http://aspace.myarchive.org/staff
    http://aspace.myarchive.org/public

This configuration described in this document is one possible approach,
and to keep things simple the following are assumed:

  *ArchivesSpace is running on a single Linux server

  *The server is running the Apache 2.2+ webserver

Unless otherwise stated, it is assumed that you have root access on
your machines, and all commands are to be run as root (or with sudo).


## Step 1: Setup proxies in your Apache configuration

The following edits can be made in the httpd.conf file itself, or in an included file:

    ProxyPass /staff http://localhost:8080/
    ProxyPassReverse /staff http://localhost:8080/
    ProxyPass /public http://localhost:8081/
    ProxyPassReverse /public http://localhost:8081/

Now restart Apache.

## Step 2: Install and configure ArchivesSpace

Follow the instructions in the main README to download and install ArchiveSpace.

Open the file `archivesspace/config/config.rb` and add the following lines:

    AppConfig[:frontend_proxy_url] = 'http://aspace.myarchive.org/staff'
    AppConfig[:public_proxy_url] = 'http://aspace.myarchive.org/public'

(Note: These lines should NOT begin with a '#' character.)

Start ArchivesSpace.

## Step 3: (Optional) Lock down ports 8080 and 8081

By default, the staff and public applications are accessible on ports 8080 and 8081

    http://aspace.myarchive.org:8080
    http://aspace.myarchive.org:8081

Since these are not the URLs at which users should access the application, you will probably
want to close them off. See README_HTTPS for more information on closing ports using iptables.
