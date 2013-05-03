# Getting started

The ArchivesSpace Import and Export tools can be run within the frontend 
ArchivesSpace application (using the appropriate menu items) or as a stand alone
CLI client of the backend application. (Note: There is no CLI for exporting at this time.)

If you wish to run the tool as a standalone CLI client, you will need to have the 'common'
directory on your classpath. If you have the entire project source checked out, you can do
that like this:

      $ export RUBYLIB={path_to_archivesspace}/common:$RUBYLIB

One you have done that, you should be able to do a 'dry-run' import using one of the
test files:

      $ cd {path_to_archivesspace}/migrations
      $ import.rb -i ead -s examples/ead/archon-tracer.xml -n

The more generalized CLI usage is as follows:
      
	    $ import.rb -i {importer-name} [-s {path/to/your/data/file.ext}]

You can see the full set of options by doing this:

      $ import.rb -h

## Running a test import (example)

You can follow the steps below to run an example import

Step 1: Follow the steps in the global README and start the application on port 8089

Step 2: Open the 'migrations' directory

	    $ cd migrations

Step 3: Create an empty repository and note the ID

	    $ rake import:make_repo

Step 4: Run a test import using the following options
		
	    $./import.rb -r {REPO_ID} -i ead -s examples/ead/afcu.xml

You can see the records that have been created using rake:

	    $ rake import:list_objects[{REPO_ID}]

## Extending and customizing import tools

If you want to adjust the behavior of one of distributed importers, make a copy and assign a new key in the first line:

      $ ASpaceImporter.importer :foo do # 'foo' is the unique key for this importer

Then make any adjustments to the logic in the 'self.configure' method. 

You can also create a new importer from scratch, using one of the three mixins or not.

The three distributed mixins are:

* XML::DOM

* XML::SAX

* CSV

Each mixin expects any class that includes it to have a 'self.configure' method that conforms to the syntax used in the examples. 

If you are writing an importer without using one of the mixins, you need to define the 'run' method in the importer.

