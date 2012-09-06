# Getting started

  * Install nokogiri, json-schema, psych

  * Run import.rb like so
  
         $ import.rb [-n ] (DRY RUN) -i {importer-name} [-s {path/to/your/data/file.ext}] [-x {path/to/your/crosswalk/file.yaml}]

# Using the import tool

## Running imports

  * Navigate to this directory (migrations)

  * Run the importer like this
		
				$./import.rb [ OPTIONS ] [ @IMPORTER ARGS ]

  * To see all importer flags, run
				
				$./import.rb -h

  * To find out what importers are available, and what to pass them
	
				$./import.rb -l
				
## Adding an Importer

  * You can create an importer and add it to the importers directory
	
  * The first line of your file must be
	
				ASpaceImporter.importer :foo do # 'foo' is the unique key for this importer

  * You must define two methods, self.profile and run. See examples.
	


