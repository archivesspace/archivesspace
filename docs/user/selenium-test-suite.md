---
title: Selenium test suite 
layout: en
permalink: /user/selenium-test-suite/ 
---

## Before running:

Run the bootstrap build task to configure JRuby and all required
dependencies:

     $ cd ..
     $ build/run bootstrap

Note: all example code assumes you are running from your ArchivesSpace
project directory.


## Running the tests:

Run the full suite:

     $ build/run selenium:test

The full suite can take a while to run. If you just want to run one
group of tests, use the *example* property:

     $ build/run selenium:test -Dexample='ArchivesSpace user interface Repositories'

See *spec/selenium_spec.rb* to find the *describe* blocks that define
groups of tests that can be run independently. As a rule, individual
examples cannot be run in isolation because each group is a sequence
of dependent steps.


## Using an already running instance of ArchivesSpace:

By default the selenium task will start up its own instances of the
backend and frontend. To use instances already running, set the
following environment variables:

     $ export ASPACE_BACKEND_URL=http://localhost:xxxx
     $ export ASPACE_FRONTEND_URL=http://localhost:xxxx


## Taking a screenshot of the interface if a test produces an error:

This can be helpful for debugging. To enable, set the following
environment variable:

     $ export SCREENSHOT_ON_ERROR=1

The screenshot will be saved to /tmp


## Interacting with selenium on the command line:

To initialize the selenium environment for IRB:

     $ ./selenium/scripts/selenium-irb.sh

When the initialization is complete, an instance of firefox will be
running under selenium control, and you will be presented with an IRB
prompt. Now you can say things like:

     > login('admin', 'admin')
     > $driver.find_element(:css, '.repository-container .btn').click
     > $driver.find_element(:link, "Create a Repository").click
     > $driver.clear_and_send_keys([:id, "repository_repo_code_"], 'REPO_1')
     > $driver.clear_and_send_keys([:id, "repository_description_"], 'First Repo')
     > $driver.find_element(:css => "form#new_repository input[type='submit']").click
     > logout
     > cleanup
     > quit

Be sure to `cleanup` before quitting as this will kill the frontend,
backend and firefox

## Interacting with selenium using pry

Add the following to 'selenium/Gemfile.local'

     gem 'pry'

Run:

     bundle install

Type:

    pry -r driver-pry.rb

Example: create a repo and login to it

    > backend_login
    > repo = create(:repo)
    > $driver.login_to_repo('admin', 'admin', repo)

