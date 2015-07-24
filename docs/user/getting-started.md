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

Currently, if you want to use Java 1.8, you will need to remove the
jdt-compiler jar library from the java classpath ( lib directory of
your ArchivesSpace directory). This will disable the use of Jasper
reports ( but not regular reports).  

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

The first time it starts, the system will take a minute or so to start
up.  Once it is ready, you should be able to point your browser to
http://localhost:8080/ and access the ArchivesSpace staff interface.

To start using the application, log in using the adminstrator account:

* Username: `admin`
* Password: `admin`

Then, you can create a new repository by selecting "System" -> "Manage
repositories" at the top right hand side of the screen.  From the
"System" menu, you can perform a variety of administrative tasks, such
as creating and modifying user accounts.  **Be sure to change the
"admin" user's password at this time.**

