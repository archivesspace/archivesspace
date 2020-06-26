---
title: UI test suites
layout: en
permalink: /user/ui-test-suites/
---
ArchivesSpace's staff and public interfaces use [Selenium](http://docs.seleniumhq.org/) to run automated browser tests. These tests can be run using [Firefox via geckodriver](https://firefox-source-docs.mozilla.org/testing/geckodriver/geckodriver/index.html) and [Chrome](https://sites.google.com/a/chromium.org/chromedriver/home) (either regular Chrome or headless).

Firefox is the default. To install geckodriver on Ubuntu Linux:

```bash
cd ~/Downloads
wget -c https://github.com/mozilla/geckodriver/releases/download/v0.26.0/geckodriver-v0.26.0-linux64.tar.gz -O - | tar -xz
sudo mv geckodriver /usr/local/bin/
```

On Mac you can use: `brew install geckodriver`.

To run using Chrome, you must first download the appropriate [ChromeDriver
executable](https://sites.google.com/a/chromium.org/chromedriver/downloads)
and place it somewhere in your OS system path.  Mac users with Homebrew may accomplish this via `brew cask install chromedriver`.

**Please note, you must have either Firefox or Chrome installed on your system to
run these tests. Consult the [Firefox WebDriver](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver)
or [ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/home)
documentation to ensure your Selenium, driver, browser, and OS versions all match
and support each other.**

## Before running:

Run the bootstrap build task to configure JRuby and all required dependencies:

     $ cd ..
     $ build/run bootstrap

Note: all example code assumes you are running from your ArchivesSpace project directory.

## Running the tests:

```bash
