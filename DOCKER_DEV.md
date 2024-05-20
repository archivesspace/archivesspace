# Git flow
- This project uses rebases instead of merges. It is important to make sure you are following the correct git flow to keep the branches consistent.
- [Playbook article here](http://playbook-staging.notch8.com/en/git/rebasing) describing how to rebase for this project

# Full Dev Env in Docker

- Pull down the code: `https://github.com/notch8/archivesspace`
- If its the first time you are working on this project, `cd` into the project and run `cp docker-compose-dev-full.yml docker-compose.yml`
- To run the project: `docker compose up app`
- You will need to migrate the database to see the app run: `docker-compose exec app ./build/run db:migrate`
- Open ports 3001 for `public`, 3000 for `frontend` and 4567 for `backend`
- To sign into the staff interface username and password are both: admin


See https://archivesspace.github.io/tech-docs/development/dev.html for additional info

# Troubleshooting

## Steps to bash into your container & bundle

1. Make sure the services section of `docker-compose.yml` looks like this (the "command" needs to be uncommented):
```
services:
  app:
    build:
      context: .
      dockerfile: Dev.dockerfile
    command: bash -l -c "tail -f /dev/null"
    depends_on:
      - db
      - solr
      - db-test
      - solr-test
    env_file:
      - .env.docker.dev
    volumes:
      - .:/archivesspace
      - build:/archivesspace/build
      - ./build/build.xml:/archivesspace/build/build.xml
    ports:
      - 3000:3000
      - 3001:3001
      - 4567:4567
```

2. start the containers: `docker-compose up app`
3. bash into the container: `docker-compose exec app bash`
4. if you need to bundle the frontend (staff interface): `./build/run bundle:frontend`
5. if you need to bundle the public interface: `./build/run bundle:public`
5. if you need to update an individual gem in the public interface: `./build/run bundle:public:update -Donly-gem=GEM-NAME-HERE`

## To start the containers separately:
1. new tab- bash into the container: `docker-compose exec app bash`
2. run the individual command to start the back end: `./build/run backend:devserver`
3. new tab- bash into the container again: `docker-compose exec app bash`
4. run the individual command to start the front end only: `./build/run frontend:devserver`

# How to use demo data in dev
1. Copy the demo db into the db docker container: `docker cp demo.sql archivesspace_db_1:/` or `docker cp demo.sql archivesspace-db-1:/` depending on the name of your docker container
  - run `docker ps` to see the name of your db container
2. bash into the container for db: `docker-compose exec db sh`
3. import the database: `mysql -p archivesspace < demo.sql`
4. password is 123456

# Running the test suite
1. Bash into the container: `docker compose exec app bash`
2. Unset frontend proxy URL: `unset APPCONFIG_FRONTEND_PROXY_URL`
  - you will need to run this each time you open a new terminal/shell, and are running frontend and Selenium specs

## The following commands will run the full set of tests for each aSpace app:
- Frontend: `./build/run frontend:test` or `./build/run frontend:selenium`
- Public: `./build/run public:test`
- Indexer: `./build/run indexer:test`
- Backend: `./build/run backend:test`

## Other useful commands for testing
- Run a single test file (you will replace the path at the end of the file or the command as needed).
  - Examples:
    - `./build/run frontend:test -Dpattern=features/repositories_spec.rb`
- Run test set for accessibility (separate commands for frontend & public) - set the ASPACE_TEST_SKIP_FIXTURES to make sure that it skips the spec helper and clears the db
    - `ASPACE_TEST_SKIP_FIXTURES=1 ./build/run rspec -Ddir="../public" -Dtag="db:accessibility" -Dspec="features" -Dorder="defined"`
    - `ASPACE_TEST_SKIP_FIXTURES=1 ./build/run rspec -Ddir="../frontend" -Dtag="db:accessibility" -Dspec="features" -Dorder="defined"`

# How to run accessibility tests
- To run the accessibility tests, the current volumes need to be removed and rebuilt with the correct database
- Run `docker compose down -v`
- Run `cp docker-compose-dev-full.yml docker-compose.yml`
- Run the project: `docker compose up app`
- You will need to migrate the database: `docker-compose exec app ./build/run db:migrate`

## How to use demo data in accessibility tests
1. Copy the demo db into the db docker container: `docker cp build/mysql_db_fixtures/accessibility.sql.gz archivesspace_db_1:/` or `docker cp build/mysql_db_fixtures/accessibility.sql.gz archivesspace-db-1:/` depending on the name of your docker container
  - run `docker ps` to see the name of your db container
2. Bash into the container for db: `docker-compose exec db sh`
3. Unzip sql file: `gzip -d < accessibility.sql.gz > accessibility.sql`
4. Import the database: `mysql -p archivesspace < accessibility.sql`
5. Password is 123456
