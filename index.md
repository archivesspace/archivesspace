---
layout: page
title: ArchivesSpace
tagline: Version 0.1.0 / 0.2.x dev
---
{% include JB/setup %}


## Overview

ArchivesSpace is a next-generation archives management tool currently under development.  

For more information about the ArchivesSpace project, vist [ArchivesSpace.org](http://www.archivesspace.org/about/).  

This page is maintained by the Hudson Molonglo development team and only provides information about the development application.

## Source Code and Documentation
     
Visit the code [repository](https://github.com/hudmol/archivesspace/).

See the code [documentation](doc/)

The application is divided into 2 parts. The backend application provides a RESTful API to the data layer. The frontend application provides a user interface built on the Rails framework. Both parts rely upon a common toolset for working with JSON representations of ASpace data.
    
## Simple Install

If you have the Java 1.6.0 SDK (or above) you can build and run a demo
server with the following commands:

     git clone git://github.com/hudmol/archivesspace.git

     cd archivesspace

     launcher/build/run dist

     java -jar launcher/archivesspace.jar

This will start the ArchivesSpace application running on:

  http://localhost:8080/

and the backend web service running on:

  http://localhost:8089/

If you'd like to use different ports, you can run:

    java -jar launcher/archivesspace.jar [frontend port] [backend port]

To create a test account and log in, you'll currently need to use
curl:

    username=$USER
    curl -v -F password=testuser "http://localhost:8089/auth/local/user/$username"




