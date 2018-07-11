---
title: ArchivesSpace Build System 
layout: en
permalink: /user/archivesspace-build-system/ 
---
==========================

## Running the build system

To run the build system, use the `build/run` script from your
ArchivesSpace project directory.  This will display a list of all
available build tasks.  This document describes a few of the important
ones.


## Bootstrapping

The bootstrap task:

     build/run bootstrap

Will bootstrap your development environment by downloading all
dependencies--JRuby, Gems, Solr, etc..


## Running a development environment

To run a development instance of all ArchivesSpace components:

     build/run backend:devserver
     build/run frontend:devserver
     build/run public:devserver
     build/run indexer

These should be run in different terminal sessions and do not need to be run
in a specific order or are all required.

For added convenience see: supervisord/README.md for a simpler way of running 
the development servers with output for all servers sent to a single terminal 
window.

You can also clear your database and search indexes with:

     build/run db:nuke

To override configuration defaults create the file `common/config/config.rb`
and set values as needed (restart the development servers). To use MySQL
for development you can set the `db_url` in `common/config/config.rb` or set
the `aspace.config.db_url` property of `JAVA_OPTS`:

```
export JAVA_OPTS="-Daspace.config.db_url=jdbc:mysql://127.0.0.1:3306/archivesspace?useUnicode=true&characterEncoding=UTF-8&user=as&password=as123"
```

See the [setup instructions](https://github.com/archivesspace/archivesspace/#running-archivesspace-against-mysql) for initializing the database.
The MySQL connector should be downloaded to `common/lib`. If you restore a
database to use in development it may not play well with the tests.

## Running the tests

ArchivesSpace uses a combination of RSpec, integration and Selenium
tests.  You will need to have Firefox on your path.  Then, to run all
tests:

     build/run test

See also: selenium/README.md for more information on the Selenium
tests.

It's also useful to be able to run the backend unit tests separately.
To do this, run:

     build/run backend:test

You can also run a single spec file with:

     build/run backend:test -Dspec="myfile_spec.rb"

or a single example with:

     build/run backend:test -Dexample="does something important"


## Coverage reports

You can run the coverage reports using:

     build/run coverage

This runs all of the above tests in coverage mode and, when the run
finishes, produces a set of HTML reports within the `coverage`
directory in your ArchivesSpace project directory.


## Building a distribution

See: README_RELEASE.md for information on building a distribution.

## Generating API documentation

See: README_RELEASE.md for information on building the documentation.
