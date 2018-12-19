---
title: Serving ArchivesSpace over subdomains
layout: en
permalink: /user/serving-archivesspace-over-subdomains/
---
This document describes how to configure ArchivesSpace and your web server to serve the application over subdomains (e.g., `http://staff.myarchive.org/` and `http://public.myarchive.org/`), which is the  recommended
practice. Separate documentation is available if you wish to [serve ArchivesSpace under a prefix](prefix.md) (e.g., `http://aspace.myarchive.org/staff` and
`http://aspace.myarchive.org/public`).

1. [Configuring Your Firewall](#Step-1%3A-Configuring-Your-Firewall)
2. [Configuring Your Web Server](#Step-2%3A-Configuring-Your-Web-Server)
   - [Apache](#Apache)
   - [Nginx](#Nginx)
3. [Configuring ArchivesSpace](#Step-3%3A-Configuring-ArchivesSpace)



## Step 1: Configuring Your Firewall

Since using subdomains negates the need for users to access the application directly on ports 8080 and 8081, these should be locked down to access by localhost only. On a Linux server, this can be done using iptables:

     iptables -A INPUT -p tcp -s localhost --dport 8080 -j ACCEPT
     iptables -A INPUT -p tcp --dport 8080 -j DROP
     iptables -A INPUT -p tcp -s localhost --dport 8081 -j ACCEPT
     iptables -A INPUT -p tcp --dport 8081 -j DROP


## Step 2: Configuring Your Web Server

### Apache

The [mod_proxy module](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html) is necessary for Apache to route public web traffic to ArchivesSpace's ports as designated in your config.rb file (ports 8080 and 8081 by default).

This can be set up as a reverse proxy in the Apache configuration like so:

      <VirtualHost *:80>
      ServerName public.myarchive.org
      ProxyPass / http://localhost:8081/
      ProxyPassReverse / http://localhost:8081/
      </VirtualHost>

      <VirtualHost *:80>
      ServerName staff.myarchive.org
      ProxyPass / http://localhost:8080/
      ProxyPassReverse / http://localhost:8080/
      </VirtualHost>

The purpose of ProxyPass is to route *incoming* traffic on the public URL (public.myarchive.org) to port 8081 of your server, where ArchivesSpace's public interface sits. The purpose of ProxyPassReverse is to intercept *outgoing* traffic and rewrite the header to match the URL that the browser is expecting to see (public.myarchive.org).

### Nginx
 > FIXME Need nginx documentation


## Step 3: Configuring ArchivesSpace

The only configuration within ArchivesSpace that needs to occur is adding your domain names to the following lines in config.rb:

     AppConfig[:frontend_proxy_url] = 'http://staff.myarchive.org'
     AppConfig[:public_proxy_url] = 'http://public.myarchive.org'

This configuration allows the staff edit links to appear on the public site to users logged in to the staff interface.

Do **not** change `AppConfig[:public_url]` or `AppConfig[:frontend_url]`; these must retain their port numbers in order for the application to run.
