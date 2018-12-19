---
title: Serving ArchivesSpace user-facing applications over HTTPS
layout: en
permalink: /user/serving-archivesspace-user-facing-applications-over-https/
---
This document describes the approach for those wishing to install
ArchivesSpace in such a manner that all end-user requests (i.e., URLs)
are served over HTTPS rather than HTTP. For the purposes of this documentation, the URLs for the staff and public interfaces will be:

  * `https://staff.myarchive.org` - staff interface
  * `https://public.myarchive.org` - public interface

The configuration described in this document is one possible approach,
and to keep things simple the following are assumed:

  * ArchivesSpace is running on a single Linux server
  * The server is running Apache or Nginx
  * You have obtained an SSL certificate and key from an authority
  * You have ensured that appropriate firewall ports have been opened (80 and 443).

1. [Configuring the Web Server](#Step-1%3A-Configure-Web-Server-(Apache-or-Nginx))
   - [Apache](#Apache)
     - [Setting up SSL](#Setting-up-SSL)
     - [Setting up Redirects](#Setting-up-Redirects)
   - [Nginx](#Nginx)
2. [Configuring ArchivesSpace](#Step-2%3A-Configure-ArchivesSpace)


## Step 1: Configure Web Server (Apache or Nginx)

### Apache
Information about configuring Apache for SSL can be found at http://httpd.apache.org/docs/current/ssl/ssl_howto.html.  You should read
that documentation before attempting to configure SSL.

#### Setting up SSL


Use the `NameVirtualHost` and `VirtualHost` directives to proxy
requests to the actual application urls. This requires the use of the `mod_proxy` module in Apache.

     NameVirtualHost *:443

     <VirtualHost *:443>
       ServerName staff.myarchive.org
       SSLEngine On
       SSLCertificateFile "/path/to/your/cert.crt"
       SSLCertificateKeyFile "/path/to/your/key.key"
       RequestHeader set X-Forwarded-Proto "https"
       ProxyPreserveHost On
       ProxyPass / http://localhost:8080/
       ProxyPassReverse / http://localhost:8080/
     </VirtualHost>

     <VirtualHost *:443>
       ServerName public.myarchive.org
       SSLEngine On
       SSLCertificateFile "/path/to/your/cert.crt"
       SSLCertificateKeyFile "/path/to/your/key.key"
       RequestHeader set X-Forwarded-Proto "https"
       ProxyPreserveHost On
       ProxyPass / http://localhost:8081/
       ProxyPassReverse / http://localhost:8081/
     </VirtualHost>

You may optionally set the `Set-Cookie: Secure attribute` by adding `Header edit Set-Cookie ^(.*)$ $1;HttpOnly;Secure`. When a cookie has the Secure attribute, the user agent will include the cookie in an HTTP request only if the request is transmitted over a secure channel.

#### Setting up Redirects
When running a site over HTTPS, it's a good idea to set up a redirect to ensure any outdated HTTP requests are routed to the correct URL. This can be done through Apache as follows:

```
<VirtualHost *:80>
ServerName staff.myarchive.org
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule (.*) https://staff.myarchive.org$1 [R,L]
</VirtualHost>

<VirtualHost *:80>
ServerName public.myarchive.org
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule (.*) https://public.myarchive.org$1 [R,L]
</VirtualHost>
```

### Nginx

> FIXME Need nginx documentation


## Step 2: Configure ArchivesSpace

The following lines need to be altered in the config.rb file:
```
AppConfig[:frontend_proxy_url] = "https://staff.myarchive.org"
AppConfig[:public_proxy_url] = "https://public.myarchive.org"
```
These lines don't need to be altered and should remain with their default values. E.g.:
```
AppConfig[:frontend_url] = "http://localhost:8080"
AppConfig[:public_url] = "http://localhost:8081"
AppConfig[:frontend_proxy_prefix] = proc { "#{URI(AppConfig[:frontend_proxy_url]).path}/".gsub(%r{/+$}, "/") }
AppConfig[:public_proxy_prefix] = proc { "#{URI(AppConfig[:public_proxy_url]).path}/".gsub(%r{/+$}, "/") }
```
