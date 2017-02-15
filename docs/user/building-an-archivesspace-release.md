---
title: Building an ArchivesSpace Release 
layout: en
permalink: /user/building-an-archivesspace-release/ 
---
-------------------------------------------------------------

## Try to tie up any loose ends

Before doing the release, it's a good idea to try and make sure nothing is left
hanging. Check JIRA for any "rejected" or started-but-not-accepted tickets,
since you don't want to ship with code that hasn't passed QA.

Also, take a look at all the Gemfile.lock files ( in backend, frontend, public,
etc ) and review the gem versions. Pay close attention to the Rails & Friends
( ActiveSupport, ActionPack, etc ), Rack, and Sinatra versions and make sure
there have not been any security patch versions. There usually are, especially
since Rails sends fix updates rather frequently.

To update the gems, update the version in Gemfile, delete the Gemfile.lock, and
run ./build/run bootstrap to download everything. Then make sure your test
suite passes.

Once everything passes, commit your Gemfiles and Gemfile.lock files.

Review the various README docs and update them as necessary. In particular the
`UPGRADING.md` instructions should be updated to reference the current and new
release version numbers.

## Clone the git repository

When building a release it is important to start from a clean repository. The safest
way of ensuring this is to clone the repo:

    git clone https://github.com/archivesspace/archivesspace.git

This assumes you will be building a release from master. To build from a tag you will
need to additionally check out the tag, like this:

    git checkout [tag-name]

## Build the ArchivesSpace technical documentation

ArchivesSpace ships with the current documentation, located in "docs"
directory. By default, this is served out at
http://localhost:8888/archivesspace when the application is running.

This documentation is also hosted on [http://archivesspace.github.io/archivesspace/](http://archivesspace.github.io/archivesspace/),
with the last released version. This documentation consists of a [Jekyll](http://jekyllrb.com/) site
build on the content of various READMEs, a [Slate](https://github.com/tripit/slate) site ( for REST API
documentation ), and the Ruby [YARD](http://yardoc.org/) documentation.

Instructions to build this can be seen on [the ArchivesSpace gh-pages branch](https://github.com/archivesspace/archivesspace/tree/gh-pages).
Important to note that these steps assume you're using a standard Ruby, not
jRuby. Note that if any additional READMEs have been added to the repository, you will
need to add those to the [scripts/build_docs.rb](https://github.com/archivesspace/archivesspace/tree/master/scripts)
script that rips apart the READMEs. Also, links in the site's side bar need to be
added to [Jekyll's
sidebar](https://github.com/archivesspace/archivesspace/blob/master/docs/_includes/sidebar.html).

Before the `build/run doc:build` step, but sure you run the `build/run backend:test` step. This will run all your tests, including the documentation_spec.rb spec, which runs through all the endpoints, generates factory girl fixture json, and spits it into a json file ( endpoint_examples.json ).

To build the documentation:

1. Check out a new branch from master:

```
  $ git checkout -b new-document
```

2. Make sure that [script/build_docs.rb](https://github.com/archivesspace/archivesspace/blob/master/scripts/build_docs.rb#L7-L8) is up-to-date and update [Jekyll's sidebar](https://github.com/archivesspace/archivesspace/blob/master/docs/_includes/sidebar.html) if necessary.

3. Bootstrap your development environment by downloading all dependencies--JRuby, Gems, Solr, etc.
```
  $ build/run bootstrap
```

4. Run the backend unit tests
```
  $ build/run backend:test
```

5. Rip apart the READMEs for content by running the doc:build ANT task

```
  $ build/run doc:build
```

6. Build Slate ( using a standard Ruby )

```
  $ cd docs/slate
  $ gem install bundler
  $ bundle install --binstubs
  $ ./bin/middleman build
  $ ./bin/middleman server # optional if you want to have a look at the site.
  $ rm -r ../api
  $ mv build ../api
```

7. Compile Jekyll

```
  $ cd docs
  $ gem install bundler
  $ bundle install --binstubs
  $ ./bin/jekyll build
  $ ./bin/jekyll serve # optional if you want to have a look at the site.
```

8. Commit the docs directory to git then push it to the gh-pages branch

```
$ cd ../ # go to top of the working tree
$ git add .
$ git commit # with appropriate commit message
$  git subtree push --prefix docs origin gh-pages
( or, if you get a FF error )
$ git push origin `git subtree split --prefix docs master`:gh-pages --force
```

9. Now merge in the docs directory back into master by committing the new-document
branch, creating a PR, and merging the PR

## Build the release

Building the actual release is very simple. Back on the master branch ( with
your docs updated ), run the following:

```
$ ./scripts/build_release vX.X.X
```

Replace X.X.X with the version number. This will build and package a release in
a zip file.

## Commit and Tag the release

The release process adds the version number to
`common/asconstants.rb`.  After you've run the `build_release`
script, you'll need to commit that file then tag the release in git.

```
$ git add common/asconstants.rb
$ git commit -m "Updating to vX.X.X"
$ git tag vX.X.X
$ git push --tags
```

## Build the release announcement

The release announcement needs to have all the tickets that make up the
changelog for the replease. In the past, this list has been written into
markdown to add in the Github release page.

An easy way to do this is to export all the relevent tickets in JIRA ( that is,
all tickets accepted since the last release  ). Then use the following script
to make a markdown file:

```
require 'csv'

def csv2md(csv_file)

output = "release_#{Time.now.to_i}.md"
file = File.open(output, "w")

CSV.foreach(csv_file, :headers => true ) do |row|
  file << "* #{ row["Issue Type"].upcase } [##{ row["Key"] }] ( https://archivesspace.atlassian.net/browse/#{ row["Key"] } ): #{ row["Summary"] }\n"
end

puts "Putting file to #{output}\n"

end

if __FILE__ == $0
  csv2md(ARGV[0])
end

```

Then make a release page in Github, upload the zip package and paste in the changelog text.

:package: :shipit: & :pray:  
