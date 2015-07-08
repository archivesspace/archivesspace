---
title: Step 1: restrict access to application urls 
layout: en
permalink: /user/step-1:-restrict-access-to-application-urls/ 
---

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

