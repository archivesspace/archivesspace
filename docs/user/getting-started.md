---
title: Getting started 
layout: en
permalink: /user/getting-started/ 
---

The quickest way to get ArchivesSpace up and running is to download
the latest distribution `.zip` file from the following URL:

  https://github.com/archivesspace/archivesspace/releases

You will need to have Java 1.6 (or newer) installed on your machine.
You can check your Java version by running the command:

     java -version

<!-- I think the caution about Java 1.8 is no longer relevant per messages from Chris in 2015. -- Christine
Currently, if you want to use Java 1.8, you will need to remove the
jdt-compiler jar library from the java classpath ( lib directory of
your ArchivesSpace directory). This will disable the use of Jasper
reports ( but not regular reports).  
--->

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

## Start ArchivesSpace

The first time it starts, the system will take a minute or so to start
up.  Once it is ready, confirm that ArchivesSpace is running correctly by 
accessing the following URLs in your browser:

  - http://localhost:8089/ -- the backend
  - http://localhost:8080/ -- the staff interface
  - http://localhost:8081/ -- the public interface
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

