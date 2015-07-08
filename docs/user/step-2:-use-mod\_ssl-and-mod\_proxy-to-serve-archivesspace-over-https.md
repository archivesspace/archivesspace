---
title: Step 2: use mod\_ssl and mod\_proxy to serve ArchivesSpace over HTTPS 
layout: en
permalink: /user/step-2:-use-mod\_ssl-and-mod\_proxy-to-serve-archivesspace-over-https/ 
---

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
