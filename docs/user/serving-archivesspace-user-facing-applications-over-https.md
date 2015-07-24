---
title: Serving ArchivesSpace user-facing applications over HTTPS 
layout: en
permalink: /user/serving-archivesspace-user-facing-applications-over-https/ 
---
==============================================================

This document describes a simple approach for those wishing to install
ArchivesSpace in such a manner that all end-user requests (i.e., URLs)
are served over HTTPS rather than HTTP.

The configuration described in this document is one possible approach,
and to keep things simple the following are assumed:

  * ArchivesSpace is running on a single Linux server

  * The server is running the Apache 2.2+ webserver

  * You have obtained an SSL certificate and key from an authority

Unless otherwise stated, it is assumed that you have root access on
your machines, and all commands are to be run as root (or with sudo).


## Step 1: restrict access to application urls

The standard ArchivesSpace distribution consists of four separate web
applications. By default, the applications are assigned to the following
urls:

  * Backend - `http://localhost:8089`
  
  * Frontend (staff UI) - `http://localhost:8080`

  * Public (read-only UI) - `http://localhost:8081` 
  
  * Solr (search middleware) - `http://localhost:8090`

These assignments can be altered through edits to the configuration file
located at `archivesspace/config/config.rb` in the standard distribution.

Since the four component applications must be able to communicate with each
other over HTTP, the first step will be to restrict access to ports `8089`,
 `8080`, `8081`, and `8090` to the localhost. On a Linux server, this can be
 done using iptables:

     iptables -A INPUT -p tcp -s localhost --dport 8089 -j ACCEPT
     iptables -A INPUT -p tcp --dport 8089 -j DROP
     iptables -A INPUT -p tcp -s localhost --dport 8080 -j ACCEPT
     iptables -A INPUT -p tcp --dport 8080 -j DROP
     iptables -A INPUT -p tcp -s localhost --dport 8081 -j ACCEPT
     iptables -A INPUT -p tcp --dport 8081 -j DROP
     iptables -A INPUT -p tcp -s localhost --dport 8090 -j ACCEPT
     iptables -A INPUT -p tcp --dport 8090 -j DROP

Once this is done, it should be possible to start up the application without
exposing it to the outside world.

## Step 2: use mod\_ssl and mod\_proxy to serve ArchivesSpace over HTTPS

In order for archivists and researchers to access the application, there will
need to be two URLs that are exposed to the outside world, and per the main
requirement of this exercise, those URLs will need to begin with `https://`.
Let's assume that they will be:

  * `https://staff.myarchive.org` - for archival staff

  * `https://research.myarchive.org` - for the public 

Start by ensuring that Apache is configured to handle HTTPS requests. Locate
the `httpd.conf` file and ensure that it contains this line (or similar):

     LoadModule ssl_module modules/mod_ssl.so

If it is commented out, uncomment it.

Likewise, ensure that the Apache mod_proxy module is enabled:

     LoadModule proxy_module modules/mod_proxy.so

The following edits can be made in the httpd.conf file itself; however, it is
conventional to use the `Include` directive to load them from a file
named `ssl.conf`, `httpd-ssl.conf`, or the like. Example:

     Include "/path/to/apache/extra/ssl.conf"

Make sure Apache is listening on port 443 (or whatever port you choose):

     Listen 443

Finally, use the `NameVirtualHost` and `VirtualHost` directives to proxy
requests to the actual application urls. Example:

     NameVirtualHost *:443

     <VirtualHost *:443>
       ServerName staff.myarchive.org
       SSLEngine On
       SSLCertificateFile "/path/to/your/cert.crt"
       SSLCertificateKeyFile "/path/to/your/key.key"
       ProxyPreserveHost On
       ProxyPass / http://localhost:8080/
       ProxyPassReverse / http://localhost:8080/
     </VirtualHost>
     <VirtualHost *:443>
       ServerName research.myarchive.org
       SSLEngine On
       SSLCertificateFile "/path/to/your/cert.crt"
       SSLCertificateKeyFile "/path/to/your/key.key"
       ProxyPreserveHost On
       ProxyPass / http://localhost:8081/
       ProxyPassReverse / http://localhost:8081/
     </VirtualHost>

More information about configuring Apache for SSL can be found at
http://httpd.apache.org/docs/current/ssl/ssl_howto.html.  You should read
that documentation before attempting to configure SSL.
