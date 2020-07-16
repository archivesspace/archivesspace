---
title: Building an ArchivesSpace release
layout: en
permalink: /user/building-an-archivesspace-release/
---
## Try to tie up any loose ends

Before doing the release, it's a good idea to try and make sure nothing is left
hanging. Check JIRA for any "rejected" or started-but-not-accepted tickets,
since you don't want to ship with code that hasn't passed QA.

Review the various README docs and update them as necessary. In particular the
`UPGRADING.md` instructions should be updated to reference the current and new
release version numbers.

Run the ArchivesSpace rake tasks to check for issues:

```
bundle # from the aspace directory, requires Ruby + Bundler
bundle exec rake check:locales
bundle exec rake check:multiple_gem_versions
```

## Clone the git repository

When building a release it is important to start from a clean repository. The safest
way of ensuring this is to clone the repo:

    git clone https://github.com/archivesspace/archivesspace.git

This assumes you will be building a release from master. To build from a tag you will
need to additionally check out the tag, like this:

    git checkout [tag-name]

## Build the ArchivesSpace technical documentation and release

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

Steps:

1. Check out a new branch from master:

```
git checkout -b $version # $version = release tag to build (i.e. v2.8.0-rc1)
```

2. Make sure that [script/build_docs.rb](https://github.com/archivesspace/archivesspace/blob/master/scripts/build_docs.rb#L7-L8) is up-to-date and update [Jekyll's sidebar](https://github.com/archivesspace/archivesspace/blob/master/docs/_includes/sidebar.html) if necessary.

3. Bootstrap your development environment by downloading all dependencies--JRuby, Gems, Solr, etc.

```
build/run bootstrap
```

4. The documentation spec file must be run to generate examples for the API docs

```
build/run backend:test -Dspec='documentation_spec.rb'
```

This runs through all the endpoints, generates factory bot fixture json, and spits it into a json file (endpoint_examples.json).

5. Update the fallback_version value in common/asconstants.rb with the new version number so that the documentation will have the correct version number in the footer

```
fallback_version = "$version.a" # version should match branch name '.a' i.e. v2.8.0-rc1.a
```

6. Rip apart the READMEs for content by running the doc:build ANT task

```
build/run doc:build
```

7. Build Slate/API docs (using a standard Ruby)
  *Note*: At present, middleman requires a bundler version < 2.0 so the docs have been updated to reflect this.

```
cd docs/slate
gem install bundler --version '< 2.0'
bundle install --binstubs
./bin/middleman build
./bin/middleman server # optional if you want to have a look at the API docs only
rm -r ../api
mv build ../api
```

8. Compile Jekyll

```
cd docs
gem install bundler
bundle install --binstubs
./bin/jekyll build
```

9. Preview the docs (optional)

```
cd docs
./bin/jekyll serve # to update bind-address add: -H 0.0.0.0
```

- http://localhost:4000/archivesspace/ # tech docs
- http://localhost:4000/archivesspace/api/ # api docs
- http://localhost:4000/archivesspace/doc/ # yard docs

10. Commit the updates to git:

```
cd ../ # go to top of the working tree
git add # all files related to the docs that just got created/updated (eg. docs/*, index.html files, etc)
git commit -m "Updating to vX.X.X"
```

11. Push docs to the gh-pages branch (do not do this with release candidates)

```
#SKIP THIS PUSH STEP FOR RELEASE CANDIDATES
git subtree push --prefix docs origin gh-pages
#or, if you get a FF error
git push origin `git subtree split --prefix docs master`:gh-pages --force
```

## Building a release

12. Building the actual release is very simple, run the following:

```
./scripts/build_release vX.X.X
```

Replace X.X.X with the version number. This will build and package a release in
a zip file.

13. Now merge the updates back into master by creating and merging a PR. This does
not require a PR review (only in this case).

14. Check out the master branch, pull, prune and tag it

````shell
git checkout master
git pull --prune
git tag vX.X.X
git push --tags
````

15. Delete the clone of ArchivesSpace used to build the release. This
is optional but recommended.

## Upload the release and prepare draft

The release announcement needs to have all the tickets that make up the
changes for the release.

```
bundle exec rake release_notes:generate[$previous_release_tag,$new_release_tag]
#example:
bundle exec rake release_notes:generate[v2.7.1,v2.8.0-rc1]
```

Then make a release page in Github:

https://github.com/archivesspace/archivesspace/releases/new

Use the new tag for the release version. Upload the zip package and paste in
the release note markdown file content.

There are some placeholder sections that need to be updated:

### Config

Significant changes to be the config file should be called out. To get the changes:

```
git diff $previous_version..$new_version -- common/config/config-defaults.rb
#example
git diff v2.7.1..v2.8.0-rc1 -- common/config/config-defaults.rb
```

Example content:

```md
Config values added:

AppConfig[:pui_search_collection_from_archival_objects]
AppConfig[:pui_search_collection_from_collection_organization]
AppConfig[:max_search_columns]
AppConfig[:hide_do_load]
AppConfig[:bulk_import_rows]
AppConfig[:bulk_import_size]

Config values removed:

None

---

See the config.rb file for more details.
```

### Database migrations

Get the latest schema version:

```
git diff --name-only $previous_version..$new_version | grep "common/db/migrations"
#example
git diff --name-only v2.7.1..v2.8.0-rc1 | grep "common/db/migrations"
```

Update the [Schema version number](release_schema_versions.md) file and PR
to techdocs. Only do the latter for a release, not release candidates.

Update the release notes under 'Database migrations' add:

```
#$n = no. of lines from git diff above, $x = the no. on the last line
This release includes $n new database migrations. The schema number for this release is $x.
```

Or remove this section if no new migrations were added.

### Other

If there are any special considerations add them here. Special considerations might
include changes that will require 3rd party plugins to be updated or a that a full
reindex is required.

Example content:

```md
This release requires a **full reindex** of ArchivesSpace for all functionality to work
correctly. Please follow the [instructions for reindexing](https://archivesspace.github.io/tech-docs/administration/indexes.html)
before starting ArchivesSpace with the new version.
```

---

When the placeholder sections have been updated or removed save the draft and share with the team.

## Post release updates

After a release has been put out it's time for some maintenance before the next
cycle of development clicks into full gear:

### Branches

Delete merged and stale branches in Github as appropriate.

### Test Servers

Review existing test servers, and request the removal of any that are no longer
needed (e.g. feature branches that have been merged for the release).

### Accessibility Scan

Run accessibility scans for both the public and staff sites and file a ticket
for any new and ongoing accessibility errors.

### PR Assignments

Begin assigning queued PRs to members of the Core Committers group, making
sure to include the appropriate milestone for the anticipated next release.

### Dependencies

#### Gems

Take a look at all the Gemfile.lock files ( in backend, frontend, public,
etc ) and review the gem versions. Pay close attention to the Rails & Friends
( ActiveSupport, ActionPack, etc ), Rack, and Sinatra versions and make sure
there have not been any security patch versions. There usually are, especially
since Rails sends fix updates rather frequently.

To update the gems, update the version in Gemfile, delete the Gemfile.lock, and
run ./build/run bootstrap to download everything. Then make sure your test
suite passes.

Once everything passes, commit your Gemfiles and Gemfile.lock files.
