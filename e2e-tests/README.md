## Archives Space End-to-End Tests

### Setup

#### Install Ruby

The currently required Ruby version is in the root folder inside the [.ruby-version](https://github.com/archivesspace/e2e-tests/blob/master/.ruby-version) file.

It is strongly recommended to use a Ruby version manager to be able to switch to any version.
The most popular version manager available for `Linux` and `macOS`, is `rbenv`.
You can find the installation guide here [https://github.com/rbenv/rbenv#readme](https://github.com/rbenv/rbenv#readme).
If you are on `Windows`, a separate `rbenv` installer exists here: [https://github.com/RubyMetric/rbenv-for-windows#readme](https://github.com/RubyMetric/rbenv-for-windows#readme).
If you wish to use a different manager or installation method, you can choose one of the following: [https://www.ruby-lang.org/en/documentation/installation/](https://www.ruby-lang.org/en/documentation/installation/)


#### How to install

Clone this repository on your machine, navigate to the root application folder, and run:


```sh
rbenv install
```

```sh
gem install bundler
```

```sh
bundle install
```

### How to run the test scenarios locally

#### Just working on e2e tests
If you are just working on e2e tests and not touching the application, you can run e2e tests locally against the latest version of archivesspace by using docker.

1. Start the latest version of ArchivesSpace locally on docker:
```
docker compose -f docker-compose.yml up
```

make sure that it is up by opening [http://localhost:8080](http://localhost:8080) on your browser.

2. Set your STAFF_URL environment variable to point your e2e tests to this server:

```
export STAFF_URL='http://localhost:8080'
```

#### With local application changes
While developing locally, you will potentially make changes to the application code and the e2e test suite. In order to run them against each other:

1. Make sure you start with a [blank database](https://docs.archivesspace.org/development/dev/#loading-data-fixtures-into-dev-database) and [blank solr index](https://docs.archivesspace.org/development/dev/#clear-out-existing-solr-state).

2. Start the `frontend:devserver` as described [here](https://docs.archivesspace.org/development/dev/#run-the-development-servers). Make sure that it is running by opening [http://localhost:3000/](http://localhost:3000/) in your browser.

3. Set your STAFF_URL environment variable to point your e2e tests to this server:

```
export STAFF_URL='http://localhost:3000'
```

### Running tests

To run all the tests, after setting your STAFF_URL environment variable, run:

```
bundle exec cucumber staff_features/
```

To run all the scenarios in a specific file:
```
bundle exec cucumber staff_features/assessments/assessment_create.feature
```

To run a specific scenario:
```
bundle exec cucumber staff_features/assessments/assessment_create.feature --name 'Assessment is created'
```

### Debugging
Add a `byebug` statement in any `.rb` file to set a breakpoint and start a debugging session in the console while running. See more [here](https://github.com/deivid-rodriguez/byebug). Don't forget to remove any `byebug` statements before pushing...

If you need to see the browser while running the test scenario and debugging, add a `HEADLESS=''` argument, as in:
```
bundle exec cucumber HEADLESS='' staff_features/
```


### Linters
```
bundle exec cuke_linter
```

```
bundle exec rubocop
```
