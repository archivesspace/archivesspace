# Getting started

The ArchivesSpace Import and Export tools can be run within the frontend 
ArchivesSpace application (using the appropriate menu items) or as a stand alone
CLI client of the backend application. (Note: There is no CLI for exporting at this time.)

If you wish to run the tool as a standalone CLI client, you will need to have the 'common'
directory on your classpath. If you have the entire project checked out, you can do
that like this:

      $ export RUBYLIB={path_to_archivesspace}/common:$RUBYLIB

One you have done that, you should be able to do a 'dry-run' import using one of the
test files:

      $ cd {path_to_archivesspace}/migrations
      $ import.rb -i xml -x ead -s examples/ead/archon-tracer.xml -n

The more generalized CLI usage is as follows:
      
	    $ import.rb -i {importer-name} [-s {path/to/your/data/file.ext}] [-x {crosswalk-name}]

You can see the full set of options by doing this:

      $ import.rb -h

## Running a test import (example)

You can follow the steps below to run an example import

Step 1: Follow the steps in the global README and start the application on port 8089

Step 2: Open the 'migrations' directory

	    $ cd migrations

Step 3: Create an empty repository and vocabulary and note their IDs

	    $ rake import:make_repo

Step 4: Run a test import using the following options
		
	    $./import.rb -r {REPO_ID} -i xml -x ead -s examples/ead/afcu.xml

You can see the records that have been created using rake:

	    $ rake import:list_objects[{REPO_ID}]

## Extending and customizing import tools

There are two ways to extend and customize the import tools. For minor adjustments to the import logic of a particular crosswalk,
you can copy that crosswalk and edit the copy to server your needs. Example:

      $ cp crosswalks/ead.yml crosswalks/ead-my-way.yml
      $ {your_favorite_text_editor} crosswalks/ead-my-way.yml
      $ ./import.rb -r {repository_id} -i xml -x ead-my-way examples/ead/afcu.xml

If you want to create a custom importer to handle other kinds of source data, you 
can create your own importer and add it to the 'importers' directory. 

The first line of your new file must be
	
	ASpaceImporter.importer :foo do # 'foo' is the unique key for this importer

You must define two methods, self.profile and run. See examples or contact the development team for more info.
	


