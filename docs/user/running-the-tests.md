---
title: Running the tests 
layout: en
permalink: /archivesspace/user/running-the-tests/ 
---

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


