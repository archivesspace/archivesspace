# Docker

The [Docker](https://www.docker.com/) configuration is used to create [automated builds](#) on Docker Hub.

## Quickstart

Run ArchivesSpace with MySQL:

```
docker network create aspace

docker run -d \
  --network=aspace \
  -p 3306:3306 \
  --name db \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -e MYSQL_DATABASE=archivesspace \
  -e MYSQL_USER=as \
  -e MYSQL_PASSWORD=as123 \
  mysql:5.7 \
  --character-set-server=utf8 \
  --collation-server=utf8_unicode_ci \
  --innodb_buffer_pool_size=2G \
  --innodb_buffer_pool_instances=2

VERSION=latest
docker run --name archivesspace -it \
  --network=aspace \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8089:8089 \
  -p 8090:8090 \
  -p 8092:8092 \
  -e APPCONFIG_DB_URL='jdbc:mysql://db:3306/archivesspace?useUnicode=true&characterEncoding=UTF-8&user=as&password=as123' \
  archivesspace/archivesspace:$VERSION
```

## Local builds

The docker-compose file can be used to test a release with MySQL built from the
current working branch:

```
docker-compose build # whenever the branch is changed
docker-compose up
```

---
