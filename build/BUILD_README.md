ArchivesSpace Build System
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

You can also clear your database and search indexes with:

     build/run db:nuke


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

To build an ArchivesSpace release, use the `build_release` script from
your project directory:

     scripts/build_release

## Generating API documentation

To generate documentation for backend endpoints:

    build/run doc:yard

The generated HTML will be placed in the `doc` directory in your archivesspace root.
