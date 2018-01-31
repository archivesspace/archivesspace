# Docker

The [Docker](https://www.docker.com/) configuration is used to create [automated builds](https://hub.docker.com/r/archivesspace/archivesspace/) on Docker Hub.

## Quickstart

Run ArchivesSpace with MySQL, external Solr and a Web Proxy:

```bash
# if you already have running containers and want to clear them out
docker-compose stop
docker-compose rm

# build the local image
docker-compose build # needed whenever the branch is changed and ready to test
docker-compose up

# running specific containers
docker-compose up db solr web
docker-compose run app bash # access app terminal
```

---
