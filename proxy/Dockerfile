# docker build --build-arg default=default.conf -t archivesspace/proxy:1.21 .
# docker tag archivesspace/proxy:1.21 archivesspace/proxy:latest
FROM nginx:1.21
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ARG default

# EMBED THE DEFAULT CONFIG, THAT'S ALL FOLKS
COPY $default /etc/nginx/conf.d/default.conf
