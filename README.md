# Getting started

If you have the Java 1.6.0 SDK (or above) you can build and run a demo
server with the following commands:

     git clone git://github.com/hudmol/archivesspace.git

     cd archivesspace

     build/run dist

     java -jar archivesspace.jar

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

# Documentation

Latest documentation is published at [http://hudmol.github.com/archivesspace/](http://hudmol.github.com/archivesspace/)