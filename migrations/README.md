# Getting started

## If using RVM (https://rvm.io//)
  
  * Install ruby (~> 1.9.3) 

         $ rvm install 1.9.3
				 $ rvm use 1.9.3

  * Create a new gemset

         $ rvm gemset create archivesspace-migrations
         $ rvm gemset use archivesspace-migrations

  * Install nokogiri, json

         $ gem install nokogiri
         $ gem install json

  * Run ead_import.rb like so
  
         $ ruby ead_import.rb {path/to/your/ead.xml}


## Without RVM

  * Why not use RVM?

