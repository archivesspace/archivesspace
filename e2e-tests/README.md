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

### How to run the tests

#### Run on the remote host
To run the tests on the `https://e2e.archivesspace.org`, run:
```
bundle exec cucumber
```

#### Run on localhost
To run the tests on localhost, you have to setup the application with:

```
docker compose -f docker-compose.yml up
```

Wait until everything is up and running.
You can check if the staff interface is running on `http://localhost:8080`.

Then, to run the tests, open another terminal, and run:
```
bundle exec cucumber HOST=localhost staff_features/
```

### Linters
```
bundle exec cuke_linter
```

```
bundle exec rubocop
```
