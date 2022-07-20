# Full Dev Env in Docker

- Pull down the code
- `cp docker-compose-dev-full.yml docker-compose.yml`
- `docker-compose up app`
- Open ports 3001 for public, 3000 for frontend and 4567 for backend
- You will need to migrate the database to see the app run: `docker-compose exec app -- ./build/run db:migrate`


See https://archivesspace.github.io/tech-docs/development/dev.html for addtional info

# How to use demo data in dev

1. Copy the demo db into the db docker container: `docker cp demo.sql archivesspace_db_1:/`
2. bash into the container for db: `dc exec db sh`
3. import the database: `mysql -p archivesspace < demo.sql`