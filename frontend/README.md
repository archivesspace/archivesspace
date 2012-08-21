# Getting started

## If using RVM (https://rvm.io//)
  
  * Install jruby (~> 1.6.7)
         $ rvm install jruby-1.6.7

  * Create a new gemset

         $ rvm gemset create archivespace-frontend
         
         $ rvm gemset use archivespace-frontend

  * Install the bundler gem

         $ gem install bundler
         
  * Run bundler to install all application gems
  
         $ bundle install
         
  * Run the Rails app
  
         $ rails server


## Without RVM

  * Grab jruby and the gem dependencies:

         $ build/run bootstrap

  * Run the Rails app:

         $ build/run frontend:devserver

