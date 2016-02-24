Managing Frontend Assets with Bower
====================================

This is aimed at developers and applies to the 'frontend' application only.

If you wish to add static assets to the core project (i.e., javascript, css, less files) please use `bower` to add and install them so we know what's what and when to upgrade.

If you wish to do a good deed for ArchivesSpace you can track down the source of any vendor assets not included in bower.json and get them updated and installed according to this protocol.

# General Setup

## Step 1: install npm

On OSX, for example:

    brew install npm

## Step 2: install Bower

    npm install bower -g

## Step 3: install components

    bower install

# Adding a static asset to ASpace Frontend (Staff UI)

## Step 1: add the component

    bower install <PACKAGE NAME> --save

## Step 2: map Bower > Rails

    Edit the bower.json file to map the assets you want from bower_components to assets. See examples in bower.json
    This is kind of a hack to workaround: https://github.com/blittle/bower-installer/issues/75

## Step 3: Install assets

    alias npm-exec='PATH=$(npm bin):$PATH'
    npm-exec bower-installer

## Step 4: Check assets in

Check the installed assets into Git. We version control bower.json and the installed files, but not the bower_components directory.

## Production!

Don't forget - if you are adding assets that don't have a .js extension, you need to add them to frontend/config/environments/production.rb 

