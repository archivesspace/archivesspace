# Getting started

  * Set up your MySQL instance

         $ mysql -uroot -p

         mysql> create database archivesspace default character set utf8;
         Query OK, 1 row affected (0.08 sec)

         mysql> grant all on archivesspace.* to 'as'@'localhost' identified by 'as123';
         Query OK, 0 rows affected (0.21 sec)


  * Edit `config/config.rb` and configure your database details

  * Run the bootstrap script to configure JRuby and all required
    dependencies:

         $ build/run bootstrap

  * Run database migrations to create the initial schema:

         $ build/run db:migrate

  * Start the dev server and connect to http://localhost:4567/

         $ build/run devserver
