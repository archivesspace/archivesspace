# Docker

Build release images for ArchivesSpace:

## Local

```
docker build -t archivesspace/build .
# to disable cache
docker build --no-cache -t archivesspace/build .
```

Run with Derby:

```
docker run --name aspace -it \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8089:8089 \
  -p 8090:8090 \
  archivesspace/build
```

Run with MySQL (container):

```
# pull and run the official mysql docker image (tweak the config according to preference)
docker run -d \
  -p 3306:3306 \
  --name mysql \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -e MYSQL_DATABASE=archivesspace \
  -e MYSQL_USER=archivesspace \
  -e MYSQL_PASSWORD=archivesspace \
  mysql:5.6 --innodb_buffer_pool_size=4G --innodb_buffer_pool_instances=4

# wait 10 seconds or so ...
docker run --name aspace -it \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8089:8089 \
  -p 8090:8090 \
  -e AS_DB_URL="jdbc:mysql://$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' mysql):3306/archivesspace?user=archivesspace&password=archivesspace&useUnicode=true&characterEncoding=UTF-8" \
  --link mysql:db \
  archivesspace/build
```

To run with an external (i.e. non-dockerized MySQL, or if using `--net-host`) simply modify the `AS_DB_URL` as appropriate. For example: `AS_DB_URL="jdbc:mysql://127.0.0.1:3306/archivesspace?user=archivesspace&password=archivesspace&useUnicode=true&characterEncoding=UTF-8"`. 

## Hub

From branch `master` for `latest`, from tag `^(1\.[5-9]\.[0-9]|[2-9]\.[0-9]\.[0-9])(-p[0-9]+|-rc[0-9]+)?$` for `{sourceref}`.

## TODO

- Continue adding to `docker/config.rb`.
- Reduce image size.
- Use non root user for image.
- Document some examples of using host volume mounts (to override config / plugins).
- Portable plugins.

Goal is to be able to use image **without** host volume mounts to make it fully portable, so need a way to get plugins into a running container (without build args because Docker Hub). What could work:

- Add wget to `startup.sh` for a (public) plugins zip (via `AS_PLUGINS_REPOSITORY`)
- Add `AS_PLUGINS` variable (string "lcnaf,local,aspace-public-formats" etc.)
- Add to `config.rb`: `AppConfig[:plugins] = ENV.fetch('AS_PLUGINS', "").split(",")`

Downsides: will download every time container is created (run for first time) and could also clash with volume mounted plugins (so would need to check plugins directory is empty first). 

## ISSUES / QUESTIONS

Maintain "shadow" `docker/config.rb`? Or, update `config-defaults.rb` with `ENV.fetch` for commonly updated configuration values?

Embedded Solr index without volume mounts will not be persisted if container is destroyed. That's a warning. Options:

- Use volume mounts (for `/archivesspace/data`)
- Use external Solr
- Add a cron job to backup / copy `/archivesspace/data` from container to host

Same applies to Derby, but that is not for production anyway. Don't use Derby =)

---
