---
layout: page
title: ArchivesSpace
tagline: Version 0.4.x-dev
---
{% include JB/setup %}


## Overview

ArchivesSpace is a next-generation archives management tool currently under development.  

For more information about the ArchivesSpace project, vist [ArchivesSpace.org](http://www.archivesspace.org/about/).  

This page is maintained by the Hudson Molonglo development team and only provides information about the development application.

## Source Code and Documentation
     
Visit the code repository at [https://github.com/hudmol/archivesspace](https://github.com/hudmol/archivesspace/).

Read the documentation at [http://hudmol.github.io/archivesspace/doc](doc/).

The application is divided into 2 parts. The backend application provides a RESTful API to the data layer. The frontend application provides a user interface built on the Rails framework. Both parts rely upon a common toolset for working with JSON representations of ASpace data.
    
## Simple Install

You will need to have at least version 1.6.0 of the Java SDK installed to run ArchivesSpace.

If you just want to try the system out, we suggest you try one of the official releases.  These are available in [the ArchivesSpace download area](https://github.com/archivesspace/archivesspace/wiki/Downloads).

Once you have a release .zip file, you can run a demo instance of the
ArchivesSpace application with the following commands:

     unzip -x archivesspace.zip

     cd archivesspace

     ./archivesspace.sh

This will start the ArchivesSpace application running on:

  http://localhost:8080/

and the backend web service running on:

  http://localhost:8089/


To set up the application, log in to the frontend application using the
adminstrator account: 

* Username: `admin`
* Password: `admin`

Create a repository after logging in. Once you have created a repository, you 
can log out and register new user accounts from the link in the log-in form.


## Building it yourself

If you have a burning desire to build the code yourself, you can run a
demo server with the following commands:

     git clone git://github.com/hudmol/archivesspace.git

     cd archivesspace

     build/run dist

This will produce a package called `archivesspace.zip`.  You can run
this by following the instructions in the previous section.
