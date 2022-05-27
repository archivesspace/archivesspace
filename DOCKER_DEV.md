# Full Dev Env in Docker

- Pull down the code
- `cp docker-compose-dev-full.yml docker-compose.yml`
- `docker-compose up app`
- Open ports 3001 for public, 3000 for frontend and 4567 for backend
- To migrate the database use `docker-compose exec app -- ./build/run db:migrate`
