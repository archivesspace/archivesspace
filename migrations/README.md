# @markup markdown
# @title ASpace Import / Export LTD.
# @author Brian Hoffman

# Getting started

## If using RVM (https://rvm.io//)
  
  * Install ruby (~> 1.9.3) 

         $ rvm install 1.9.3
				 $ rvm use 1.9.3

  * Create a new gemset

         $ rvm gemset create archivesspace-migrations
         $ rvm gemset use archivesspace-migrations

  * Install nokogiri, json-schema

         $ gem install nokogiri
         $ gem install json-schema

  * Run import.rb like so
  
         $ import.rb [-n ] (DRY RUN) -i {importer-name} {path/to/your/data/file.ext}


## Without RVM

  * This should work as long as you are using Ruby 1.9; Please report on any problems you have in your environment

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
	
				```
				ASpaceImporter.importer :foo do # 'foo' is the unique key for this importer
				```
  * You must define two methods, self.profile and run. See examples.
	


