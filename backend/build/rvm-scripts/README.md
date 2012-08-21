# RVM Build Scripts

This directory contains some alternate bash scripts for developers using RVM. The main
difference between these scripts and the default build routines is that the scripts in
this directory will install gems in your .rvm/jurby@global gemset. (If you want to use
a dedicated gemset for archivesspace-backend, you can modify the bootstrap script to 
do so.)

					$ ./bootstrap.rb

The remaining scripts just mimic the scripts in the build directory. First:

					$ ./migrate_db_rmv.rb [nuke]

This will start up a derby development DB. Next:

					$ ./devserver_rvm.rb

This will start the service.