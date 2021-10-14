## Contributing

Thank you for considering contributing to ArchivesSpace. It's people
like you that make ArchivesSpace such a wonderful application.

## Where do I go from here?

If you have found a bug or have an idea for an enhancement or new feature,
check our tracking systems to see if someone else in the community has already
created a ticket. The majority of the open tickets are kept in our [development catalog](https://archivesspace.atlassian.net/projects/ANW/issues/ANW-418?filter=allopenissues) but there are also issues in the [ArchivesSpace GitHub repository](https://github.com/archivesspace/archivesspace/issues).

If there isn't a ticket in either of those systems, go ahead and make one. Be
sure to include a **title and clear description** with as much relevant
information as possible including **screen shots, example data, and import or
export files**, and, if applicable, a **code sample** or an **executable test
case** demonstrating the expected behavior that is not occurring.

## Fork & create a branch

When you are ready to start working on an issue, please assign it to yourself
as an indication that you are working on it. Then [fork ArchivesSpace][] and
create a branch with a descriptive name.

A good branch name would include the ticket number in it. For example, if you
are working on JIRA ticket ANW-123:

```sh
git checkout -b ANW-123-descriptive-short-title
```

## Get the test suite running

### Bootstrap

Before running any tests, you will need to set up your environment using the
ArchivesSpace build system. From the top level directory, type

```sh
build/run bootstrap
```

ArchivesSpace has several test suites that can be run individually or all at
once. NOTE: running all test suites can take a while to run. The test suites that
are most applicable are:

* backend:test - database and API unit tests
* frontend:test - staff interface unit tests
* public:test - public user interface unit tests
* indexer:test - indexer unit tests
* headless-tests - runs all unit test suites

To run any (or all) of the test suites, use the build system. To run the backend
unit tests:

```sh
build/run backend:test
```

## Implement your fix, enhancement or new feature

At this point, you're ready to make your changes! Feel free to ask for help;
remember everyone is a beginner at first

* ArchivesSpace Core Committer's Group - ArchivesSpaceCoreCommitters@lyrasis.org
* ArchivesSpace Program Team - ArchivesSpaceHome@lyrasis.org

## Look at the impact of your changes

ArchivesSpace has two separate user interfaces - staff and public - so make sure
to take a look at your changes in the application prior to submitting a pull
request.

### Running components locally

After you have [bootstrapped the environment](#bootstrap), you can run a
development instance of all ArchivesSpace components. Without any configuration,
the devservers will spin up an Apache Derby database which will disappear once the
devservers have been stopped.

#### Database and API
    build/run backend:devserver

#### Staff Interface
    build/run frontend:devserver

#### Public User Interface    
    build/run public:devserver

#### Indexer for both interfaces
    build/run indexer

These development servers should be run in different terminal/command window
sessions. To shut them down, use Control-c.

To look at changes that impact the staff interface, you will need to start up
the backend and frontend devservers and the indexer.

You should now be able to open <http://localhost:3000> in your browser and see
the staff interface. You can log in using:

*User*: admin
*Password*: admin

For the public user interface, you will need to start up the backend and public
devservers and the indexer.

You should now be able to open <http://localhost:3001> in your browser and see
the public user interface.

## Make a Pull Request

At this point, you should switch back to your master branch and make sure it's
up to date with ArchivesSpace's master branch:

```sh
git remote add upstream git@github.com:archivesspace/archivesspace.git
git checkout master
git pull upstream master
```

Then update your feature branch from your local copy of master, and push it!

```sh
git checkout ANW-123-descriptive-short-title
git rebase master
git push --set-upstream origin ANW-123-descriptive-short-title
```

Finally, go to GitHub and [make a Pull Request][] :D

TravisCI will run all test suites against the pushed branch. We care about
quality, so your Pull Request won't be merged until all test suites pass.

### What happens after you submit a Pull request?

All Pull Requests are reviewed by at least one member of the ArchivesSpace [Core Committer's Group](https://archivesspace.atlassian.net/wiki/spaces/ADC/pages/102893918/Core+Committers+Group).

A core committer reviews the issue/ticket associated with the Pull Request to make
sure they understand what the code changes are supposed to do. Next, they review
the code changes to see the proposed solution. Then they checkout the branch to
test the solution in a running instance of ArchivesSpace.

During the review, the core committer may have comments or ask questions in the
Pull Request. Once the comment/questions have been answered/resolved, a Pull
Request can only be accepted and merged into the core code base by a core
committer if:

* All test suites are passing.
* It is up-to-date with current master.

### Keeping your Pull Request updated

If a member of the core committer's group asks you to "rebase" your Pull Request,
they're saying that a lot of code has changed, and that you need to update your
branch so it's easier to merge.

To learn more about rebasing in Git, there are a lot of [good][git rebasing]
[resources][interactive rebase] but here's the suggested workflow:

```sh
git checkout ANW-123-descriptive-short-title
git pull --rebase upstream master
git push --force-with-lease ANW-123-descriptive-short-title
```

## Resources

[ArchivesSpace website](https://archivesspace.org/)
[ArchivesSpace Wiki](https://archivesspace.atlassian.net/wiki/spaces/ADC/overview)

### Documentation

ArchivesSpace Technical Documentation is maintained in the [tech-docs repository](https://github.com/archivesspace/tech-docs).

### YouTube channels/videos

From development partner Hudson Molongo:
https://www.youtube.com/channel/UCMBmBY_CsxwJy9rJKxQrVoQ

ArchivesSpace:
https://www.youtube.com/channel/UCxR6D-UlSx6N6UWTeqHTjzA

[make a pull request]: https://help.github.com/articles/creating-a-pull-request
[git rebasing]: http://git-scm.com/book/en/Git-Branching-Rebasing
[interactive rebase]: https://help.github.com/articles/interactive-rebase
