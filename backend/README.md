# Getting started

To run an instance of the ArchivesSpace backend, first run the
following command to fetch JRuby and all dependencies:

         $ build/run bootstrap

Once you've done that, you can either run the backend in demo mode
(using an Apache Derby database), or by pointing it at an existing
MySQL server.


## Running in demo mode

Simply run:

         $ build/run backend:devserver

To start the backend.  An Apache Derby database will be automatically
created for you.  You can connect to the dev server on
http://localhost:4567/


## Running with MySQL

  * Create a database for your ArchivesSpace instance and grant access to a user:

         $ mysql -uroot -p

         mysql> create database archivesspace default character set utf8;
         Query OK, 1 row affected (0.08 sec)

         mysql> grant all on archivesspace.* to 'as'@'localhost' identified by 'as123';
         Query OK, 0 rows affected (0.21 sec)

  * Copy `config/config-example.rb` to `config/config.rb` and edit the `:db_url` configuration entry to match the details of your database.

  * Run database migrations to create the initial schema:

         $ build/run db:migrate

  * Start the dev server and connect to http://localhost:4567/

         $ build/run backend:devserver
