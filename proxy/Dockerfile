# docker build [--build-arg DEFAULT_CFG=default.conf] -t archivesspace/proxy:stable .
# docker tag archivesspace/proxy:stable archivesspace/proxy:latest
FROM nginx:stable
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ARG DEFAULT_CFG=default.conf

# EMBED THE DEFAULT CONFIG, THAT'S ALL FOLKS
COPY $DEFAULT_CFG /etc/nginx/conf.d/default.conf
