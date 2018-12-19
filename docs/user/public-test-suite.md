---
title: Public test suite
layout: en
permalink: /user/public-test-suite/
---
ArchivesSpace's public interface uses [Selenium](http://docs.seleniumhq.org/) to run automated browser tests. These tests can be run using [Firefox via geckodriver](https://firefox-source-docs.mozilla.org/testing/geckodriver/geckodriver/index.html) and [Chrome](https://sites.google.com/a/chromium.org/chromedriver/home) (either regular Chrome or headless).

Firefox is the default, and ArchivesSpace ships with the appropriate Firefox Webdriver executables for OSX and Linux.

To run using Chrome, you must first download the appropriate [ChromeDriver
executable](https://sites.google.com/a/chromium.org/chromedriver/downloads)
and place it somewhere in your OS system path.  Mac users with Homebrew may accomplish this via `brew cask install chromedriver`. Then export a SELENIUM_CHROME environment variable, e.g:

     $ export SELENIUM_CHROME=true

or

     $ export SELENIUM_HEADY_CHROME=true

When you run the tests (see below), a Chrome session will be launched in either headless or heady mode.

***Please note, you must have either Firefox or Chrome installed on your system to
run these tests. Consult the [Firefox WebDriver](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver)
or [ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/home)
documentation to ensure your Selenium, driver, browser, and OS versions all match
and support each other.  As of November 2018 only post-Quantum versions of Firefox (v. 57+) are supported via the built-in geckodriver.***

## Before running:

Run the bootstrap build task to configure JRuby and all required dependencies:

     $ cd ..
     $ build/run bootstrap

Note: all example code assumes you are running from your ArchivesSpace project directory.


## Running the tests:

Run the full suite:

     $ build/run public:test

As a rule, individual examples cannot be run in isolation because each group is a sequence of dependent steps.
