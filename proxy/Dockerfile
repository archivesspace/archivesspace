# docker build [--build-arg DEFAULT_CFG=default.conf] -t archivesspace/proxy:1.21 .
# docker tag archivesspace/proxy:1.21 archivesspace/proxy:latest
FROM nginx:1.21
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ARG DEFAULT_CFG=default.conf

# EMBED THE DEFAULT CONFIG, THAT'S ALL FOLKS
COPY $DEFAULT_CFG /etc/nginx/conf.d/default.conf
