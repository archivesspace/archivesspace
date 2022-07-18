# Full Dev Env in Docker

- Pull down the code
- `cp docker-compose-dev-full.yml docker-compose.yml`
- `docker-compose up app`
- Open ports 3001 for public, 3000 for frontend and 4567 for backend
- You will need to migrate the database to see the app run: `docker-compose exec app -- ./build/run db:migrate`


See https://archivesspace.github.io/tech-docs/development/dev.html for addtional info
# Troubleshooting

### Steps to bash into your container & bundle archivesspace frontend

1. Make sure the services section of `docker-compose.yml` looks like this:
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

2. start the containers: `dc up app`
3. bash into the container: `dc exec app bash`
4. bundle the frontend `./build/run bundle:frontend`
5. inside the container still- run the individual command to start the back end: `./build/run backend:devserver`
6. new tab- bash into the container again: `dc exec app bash`
7. run the individual command to start the front end only: `./build/run frontend:devserver`