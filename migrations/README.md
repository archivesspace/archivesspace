# Getting started

Install nokogiri, json-schema, psych

Basic usage of import.rb is like this:
  
	$ import.rb -i {importer-name} [-s {path/to/your/data/file.ext}] [-x {crosswalk-name}]

# Using the import tool

## Running a test import (example)

You can follow the steps below to run an example import

Step 1: Follow the steps in the global README and start the application on port 8089

Step 2: Open the 'migrations' directory

	$ cd migrations

Step 3: Create an empty repository and vocabulary and note their IDs

	$ rake import:make_repo
	$ rake import:make_vocab

Step 4: Run a test import using the following options
		
	$./import.rb -r {REPO_ID} -v {VOCAB_ID} -i xml -x ead -s examples/ead/afcu.xml

You can see the records that have been created using rake:

	$ rake import:list_objects[{REPO_ID}]
	$ rake import:list_subjects[{VOCAB_ID}]

To see all importer flags, run
				
	$./import.rb -h

To find out what importers are available, and what to pass them
	
	$./import.rb -l

## Adding an Importer

You can create an importer and add it to the importers directory
	
The first line of your file must be
	
				ASpaceImporter.importer :foo do # 'foo' is the unique key for this importer

You must define two methods, self.profile and run. See examples or contact the development team for more info.
	


