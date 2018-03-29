# Docker

The [Docker](https://www.docker.com/) configuration is used to create [automated builds](https://hub.docker.com/r/archivesspace/archivesspace/) on Docker Hub,
which are deployed to http://test.archivesspace.org when the build completes.

## Custom builds

Run ArchivesSpace with MySQL, external Solr and a Web Proxy. Switch to the
branch you want to build:

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

## Sharing an image

To share the build image the easiest way is to create an account on [Docker Hub](https://hub.docker.com/).
Next retag the image and push to the hub account:

```bash
DOCKER_ID_USER=example
TAG=awesome-updates
docker tag archivesspace_app:latest $DOCKER_ID_USER/archivesspace:$TAG
docker push $DOCKER_ID_USER/archivesspace:$TAG
```

To download the image: `docker pull example/archivesspace:awesome-updates`.

---
