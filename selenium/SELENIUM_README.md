# Selenium test suite

ArchivesSpace uses [Selenium](http://docs.seleniumhq.org/) to run automated
browser testing. Currently, you can run ArchivesSpace Selenium tests using
[Firefox](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver) 
and [Chrome](https://sites.google.com/a/chromium.org/chromedriver/home).
Firefox is the default, and ArchivesSpace ships with the Firefox Webdriver
executables for OSX and Linux.

To run using Chrome, you must first download the [ChromeDriver
execuitable](https://sites.google.com/a/chromium.org/chromedriver/downloads)
and place it somewhere in your OS system path. Then export a SELENIUM_CHROME enviroment
variable, e.g:

     $ export SELENIUM_CHROME=true

When you run the tests ( see below  ), Selenium should launch a Chrome session
in headless mode.

***Please note, you must have either Firefox or Chrome installed on your system to
run these tests. Consult the [Firefox WebDriver](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver) 
or [ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/home)
documentation to ensure your Selenium, driver, browser, and OS versions all match
and support each other.*** 

## Before running:

Run the bootstrap build task to configure JRuby and all required
dependencies:

     $ cd ..
     $ build/run bootstrap

Note: all example code assumes you are running from your ArchivesSpace
project directory.


## Running the tests:

Run the full suite:

     $ build/run selenium:staff

The full suite can take a while to run. The selenium:staff task will run tests
in parallel, with 2 browser sessions being run on default. You can adjust the
number of sessions by passing a -Dcores to your selenium:staff task, e.g: 

     $ build/run selenium:staff -Dcores=6
   
As a general rule, you don't want the number of Selenium sessions to execeed the 
number of processor cores, since this will just cause the tests to run slowly.


If you want to run just one spec, use the *spec* property:
     
     $ build/run selenium:test -Dspec=merge_and_transfer_spec.rb

If you just want to run one group of tests, use the *example* property:

     $ build/run selenium:test -Dexample='ArchivesSpace user interface Repositories'

***NOTE THE CHANGE BETWEEN 'selenium:staff' and 'selenium:test'.*** 

As a rule, individual examples cannot be run in isolation because each group is a sequence
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

A timestamped screenshot png will be saved to /tmp. To change the save
location, export an enviornment variabled called SCREENSHOT_DIR to point to a
different directory. 

## Logging the output

The results will be put into a 'log' folder in your OS' temporary directory (
i.e. /tmp ). You can change this by exporting a SELENIUM_LOG_DIR enviorment
variable to the session running Selenium.

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

