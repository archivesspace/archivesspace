# ArchivesSpace End-to-End Test Suite

## Recommended setup

### Using a Ruby version manager

The required Ruby version for the e2e test application is documented in `[./.ruby-version](./.ruby-version)`.

It is strongly recommended to use a Ruby version manager to be able to switch to any version that a given project requires.

#### `rbenv`

We recommend using the [`rbenv`](https://rbenv.org/) Ruby version manager.

#### Linux and macOS

Find the installation guide here: [https://github.com/rbenv/rbenv#readme](https://github.com/rbenv/rbenv#readme).

#### Windows

A Windows `rbenv` installer exists here: [https://github.com/RubyMetric/rbenv-for-windows#readme](https://github.com/RubyMetric/rbenv-for-windows#readme).

#### Alternatives to `rbenv`

If you wish to use a different Ruby manager or installation method, see [Ruby's installation documentation](https://www.ruby-lang.org/en/documentation/installation/).

### Installation

From the ArchivesSpace root directory, navigate to the e2e test application, then install Ruby, Bundler, and the application dependencies:

```sh
# 1. Navigate to e2e-tests directory
cd e2e-tests

# 2. Install Ruby at the version specified in ./.ruby-version
rbenv install

# 3. Install the Bundler dependency manager
gem install bundler

# 4. Install project dependencies
bundle install
```

## Running the tests locally

### Just working on the e2e tests with Docker

If you are just working on e2e tests and not touching the ArchivesSpace application, you can run e2e tests locally against the latest ArchivesSpace `master` branch build using Docker.

#### Install Docker Desktop

[Docker Desktop](https://www.docker.com/get-started/) is a one-click-install application for Linux, Mac, and Windows. It provides both terminal and GUI access to Docker. Download and install the appropriate version for your operating system from the link above.

#### Run the latest ArchivesSpace Docker image

```sh
# Get the latest ArchivesSpace `master` branch build
docker compose pull

# Start ArchivesSpace servers
docker compose up
```

Verify the servers are running by opening [http://localhost:8080](http://localhost:8080) in a browser.

### Working with an ArchivesSpace development environment

You can run the e2e test suite against your local ArchivesSpace development environment. But be aware that your database, Solr index, and any configuration changes will need to be reset.

#### Reset your database and Solr index

Make sure your ArchivesSpace instance has a [blank database](https://docs.archivesspace.org/development/dev/#loading-data-fixtures-into-dev-database) and [blank solr index](https://docs.archivesspace.org/development/dev/#clear-out-existing-solr-state).

#### Restore default configuration options (except for `AppConfig[:db_url]`)

Make sure you override any local changes to the default configuration options (via ../common/config/config.rb) by commenting them out or deleting them, except for `AppConfig[:db_url]` (which is required for using the MySQL database).

#### Run the frontend dev server

Start the `frontend:devserver` as described [here](https://docs.archivesspace.org/development/dev/#run-the-development-servers). Verify it is running by opening [http://localhost:3000/](http://localhost:3000/) in your browser.

#### Set the `STAFF_URL` environment variable

Set your `STAFF_URL` environment variable to point the e2e tests at the local development server:

```sh
export STAFF_URL='http://localhost:3000'
```

## Running tests

After setting the appropriate `STAFF_URL` environment variable as described above, run the desired test(s) according to the following commands.

### All test files at once

```sh
bundle exec cucumber staff_features/
```

### All scenarios in a specific file

```sh
bundle exec cucumber staff_features/assessments/assessment_create.feature
```

### A specific scenario in a specific file

```sh
bundle exec cucumber staff_features/assessments/assessment_create.feature --name 'Assessment is created'
```

## Debugging

Add a `byebug` statement in any `.rb` file to set a breakpoint and start a debugging session in the console while running. See more [here](https://github.com/deivid-rodriguez/byebug). Don't forget to remove any `byebug` statements before pushing...

If you need to see the browser while running the test scenario and debugging, add a `HEADLESS=''` argument, as in:

```sh
bundle exec cucumber HEADLESS='' staff_features/
```

## Linters

This test suite uses two linters, [`cuke_linter`](https://github.com/enkessler/cuke_linter) and [`rubocop`](https://rubocop.org/), to maintain code quality.

```sh
# Lints Cucumber .feature files
bundle exec cuke_linter

# Lints Ruby .rb files
bundle exec rubocop
```
