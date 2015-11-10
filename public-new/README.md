ArchivesSpace Public UI Development Branch
====================================

This is a development project to replace the ArchivesSpace Public UI in Spring 2016.

# Overview

You can make the `public:devserver` ant task point to this application by doing `export ASPACE_PUBLIC_DEV=true`.

To get the development server running using the standard development build tools, do this:

* Open two terminal windows
* In each window:

     `cd archivesspace`
     `export ASPACE_PUBLIC_DEV=true`

* In window 1:
     `./build/run boostrap`
     `./build/run backend:devserver`

* In window 2:
     `./build/run public:devserver`

Point your browser to `http://localhost:3001`


# Development Notes

See the `README_BOWER.md` file in the `frontend` for guidelines on managing frontend assets.

Unlike existing ASpace applications, this app uses Rails 4.

## Javascript

The javascript layer currently uses Exoskeleton (a drop-in replacement for BackboneJS), Jquery, and Lodash.

## CSS

The CSS layer will probably use Foundation CSS or Twitter Bootstrap.


# Contributing

Yes, please do it - especially if you are a master of CSS and HTML with an interest in graphic design. You can sign up by adding your name and how you'd like to contribute to this list and submitting a pull request.

Yes, I'd like to contribute:

Name     Notes
