Running ArchivesSpace under Tomcat
----------------------------------

ArchivesSpace is packaged as a set of `.war` files, so you can run it
under any servlet container you like.  Unless you have particular
needs, we recommend you use the standard method described in README.md
(which uses an embedded Jetty container).

However, if you have a burning desire to use Tomcat, the steps are:

  * Download the archivesspace zip distribution, and the Tomcat
    distribution.

  * Unpack the archivesspace distribution and modify the
    config/config.rb file to point to your MySQL database (if you're
    using MySQL).  Something like:

      AppConfig[:db_url] = "jdbc:mysql://localhost:3306/archivesspace?user=as&password=as123&useUnicode=true&characterEncoding=UTF-8"

  * Unpack the Tomcat distribution

  * From your 'archivesspace' directory, use the 'configure-tomcat.sh'
    script to copy everything over to your Tomcat directory

  * Install the MySQL connector into Tomcat's 'lib' directory.


On my system, that looks like this:

     $ ls
     apache-tomcat-7.0.47.tar.gz  archivesspace-v1.0.1.zip

     # Unpack both
     $ tar xf apache-tomcat-7.0.47.tar.gz
     $ unzip -q archivesspace-v1.0.1.zip

     $ cd archivesspace

     (edit config/config.rb to include the AppConfig[:db_url] setting)

     # Now configure the Tomcat directory
     $ scripts/configure-tomcat.sh ../apache-tomcat-7.0.47
     Loading ArchivesSpace configuration file from path: /home/mst/tmp/tomcat/archivesspace/config/config.rb
     Loading ArchivesSpace configuration file from path: /home/mst/tmp/tomcat/archivesspace/config/config.rb
     Copying '/home/mst/tmp/tomcat/archivesspace/wars/backend.war' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/webapps-backend/ROOT.war'
     Copying '/home/mst/tmp/tomcat/archivesspace/wars/frontend.war' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/webapps-frontend/ROOT.war'
     Copying '/home/mst/tmp/tomcat/archivesspace/wars/public.war' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/webapps-public/ROOT.war'
     Copying '/home/mst/tmp/tomcat/archivesspace/wars/indexer.war' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/webapps-solr'
     Copying '/home/mst/tmp/tomcat/archivesspace/wars/solr.war' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/webapps-solr/ROOT.war'
     Copying '/home/mst/tmp/tomcat/archivesspace/gems/gems/jruby-jars-1.7.6/lib/jruby-core-complete-1.7.6.jar' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/lib'
     Copying '/home/mst/tmp/tomcat/archivesspace/gems/gems/jruby-jars-1.7.6/lib/jruby-stdlib-complete-1.7.6.jar' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/lib'
     Copying '/home/mst/tmp/tomcat/archivesspace/lib/common.jar' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/lib'
     Copying '/home/mst/tmp/tomcat/archivesspace/lib/jsoup-1.7.2.jar' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/lib'
     Copying '/home/mst/tmp/tomcat/archivesspace/gems/gems/jruby-rack-1.1.12/lib/jruby-rack-1.1.12.jar' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/lib'
     Copying '/home/mst/tmp/tomcat/archivesspace/gems' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/lib'
     Copying '/home/mst/tmp/tomcat/archivesspace/locales' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47'
     Copying '/home/mst/tmp/tomcat/archivesspace/launcher/tomcat/files/setenv.sh' to '/home/mst/tmp/tomcat/apache-tomcat-7.0.47/bin'
     Writing server.xml
     Writing skeleton config file to /home/mst/tmp/tomcat/apache-tomcat-7.0.47/conf/config.rb

     # Grab the MySQL connector and put it somewhere Tomcat can find it
     $ cd ../apache-tomcat-7.0.47/lib
     $ curl -Oq http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.24/mysql-connector-java-5.1.24.jar

     # Start Tomcat
     $ cd ../
     $ bin/startup.sh


If you left the ports as default in your config/config.rb file, you
should be able to connect to ArchivesSpace on http://localhost:8080/ at
this point (and the logs/catalina.out file will confirm that everything
started up)
