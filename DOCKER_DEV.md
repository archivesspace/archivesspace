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

## Steps to bash into your container & bundle archivesspace frontend

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
6. inside the container still- run the individual command to start the back end: `./build/run backend:devserver`
7. new tab- bash into the container again: `docker-compose exec app bash`
8. run the individual command to start the front end only: `./build/run frontend:devserver`

# How to use demo data in dev
1. Copy the demo db into the db docker container: `docker cp demo.sql archivesspace_db_1:/` or `docker cp demo.sql archivesspace-db-1:/` depending on the name of your docker container
  - run `docker ps` to see the name of your db container
2. bash into the container for db: `docker-compose exec db sh`
3. import the database: `mysql -p archivesspace < demo.sql`
4. password is 123456