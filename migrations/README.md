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

  * Why not use RVM?

