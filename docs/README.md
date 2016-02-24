## ArchivesSpace Technical Documentation

This is the documentation for ArchivesSpace (http://archivesspace.org)

## How to contribute

Fork the ArchivesSpace repository, read the rest of this README file and make some changes.
Once you're done with your changes send a pull request. Thanks!

## Content

All of the pages for the documentation are generated from the README markdown
files in the ArchivesSpace repository. Take a look at the
[scripts/build_docs.rb](https://github.com/archivesspace/archivesspace/tree/master/scripts) to 
see which READMEs are included. This script breaks up the READMEs into their
own pages, with each h1 sections ( or sections starting with "#" in markdown )
into their own pages. 

To build all the documentation, use the 
```
build/run doc:build
```
to assemble all the documentation. 

You will then need to complie the Slate and  Jekyll...

## Slate

[Slate](https://github.com/tripit/slate) is a nice way to make good looking API 
documentation. Once you've run the doc:build step, you will need to compile 
the HTML.

First, go to docs/slate.

Make sure you have Ruby and RubyGems installed. Next install
[bundler](http://bundler.io/):

    gem install bundler

Then install dependencies:

    bundle install --binstubs

Then compile the Slate files:

    ./bin/middleman build

This will make a directory called "build" in the slate directory. Move this
directory to replace the  the docs/API directory.

## Jekyll

Jekyll is another static HTML site, which is used for the general documentation
that was ripped from all the READMEs. This also needs to be compiled.

Go to the docs directory.

Make sure you have Ruby and RubyGems installed. Next install
[bundler](http://bundler.io/):

    gem install bundler

Then install dependencies:

    bundle install --binstubs

Then compile the site:

    ./bin/jekyll build

This will create a site in the _site directory. 

## Pushing to Github pages

If you have commit access to the ArchivesSpace repository, you can publish the
documents to the [Github pages](http://archivesspace.github.io/archivesspace). 

To do this, run the doc:build command, compile Slate and Jekyll, and commit the
docs ( you can do this to a branch other than master ). Then run:

```
 git subtree push --prefix docs origin gh-pages
```

or ( this the tree is wacked up, you might get a FF error..that's ok, because
the gh-pages branch is ephemeral )

```
git push origin `git subtree split --prefix docs master`:gh-pages --force
```

## License

Distributed under the MIT license. 
