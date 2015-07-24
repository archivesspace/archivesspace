---
title: Running ArchivesSpace under a prefix 
layout: en
permalink: /user/running-archivesspace-under-a-prefix/ 
---
------------------------------------

It's recommended to run each ArchivesSpace instance with its own host name on the root path e.g. http://myarchivesspace.example.com/.

However, if you are required run ArchivesSpace under a prefix e.g. http://example.com/myarchivesspace, then there will be a few extra steps to your deployment.

1. For the version you're working with, go to the Github repository e.g. http://github.com/archivesspace/archivesspace/tree/v1.0.2 and click the `Download ZIP` button on the right of the screen.  This will download the ArchivesSpace source code to your machine.
2. When you unzip this file it will create a directory containing the source code of the application.  In this directory, create a sub-directory called `config` containing a file `config.rb`.  Edit this file and add the following line(s) with your desired deployment URL including the prefix:

     AppConfig[:frontend_url] = "http://example.com/myarchivesspace"
     AppConfig[:public_url] = "http://example.com/mypublicarchivesspace"
3. Open a command prompt and change directory to your unpacked ArchivesSpace directory.  Run the following command:

     unix$ build/run dist
     windows> build\run.bat dist
4. This will create a custom ArchivesSpace deployment that will support the prefix you defined.  Follow the Getting Started instructions to deploy this package as normal.
