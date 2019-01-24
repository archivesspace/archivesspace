---
title: Getting started with ArchivesSpace
layout: en
permalink: /user/getting-started-with-archivesspace/
---
## System requirements

* Java 1.7 or 1.8.
* At least 1024 MB RAM allocated to the application; at least 2 GB for optimal performance.

ArchivesSpace has been tested on Ubuntu Linux, Mac OS X, and
Windows.

MySQL is not required, but is **strongly** recommended for production use.

**The embedded database is for testing purposes only. You should use MySQL for
any data intended for production, including data in a test instance that you
intend to move over to a production instance.**

## Getting started

The quickest way to get ArchivesSpace up and running is to download
the latest distribution `.zip` file from the following URL:

  https://github.com/archivesspace/archivesspace/releases

You will need to have Java 1.7 or 1.8 installed on your machine.
You can check your Java version by running the command:

     java -version

When you extract the `.zip` file, it will create a directory called
`archivesspace`.  To run the system, just execute the appropriate
startup script for your platform.  On Linux and OSX:

     cd /path/to/archivesspace
     ./archivesspace.sh

and for Windows:

     cd \path\to\archivesspace
     archivesspace.bat

This will start ArchivesSpace running in foreground mode (so it will
shut down when you close your terminal window).  Log output will be
written to the file `logs/archivesspace.out` (by default).

**Note:** If you're running Windows and you get an error message like
`unable to resolve type 'size_t'` or `no such file to load -- bundler`,
make sure that there are no spaces in any part of the path name in which the
ArchivesSpace directory is located.

### Start ArchivesSpace

The first time it starts, the system will take a minute or so to start
up.  Once it is ready, confirm that ArchivesSpace is running correctly by
accessing the following URLs in your browser:

  - http://localhost:8089/ -- the backend
  - http://localhost:8080/ -- the staff interface
  - http://localhost:8081/ -- the public interface
  - http://localhost:8082/ -- the OAI-PMH server
  - http://localhost:8090/ -- the Solr admin console


To start using the Staff interface application, log in using the adminstrator
account:

* Username: `admin`
* Password: `admin`

Then, you can create a new repository by selecting "System" -> "Manage
repositories" at the top right hand side of the screen.  From the
"System" menu, you can perform a variety of administrative tasks, such
as creating and modifying user accounts.  **Be sure to change the
"admin" user's password at this time.**
