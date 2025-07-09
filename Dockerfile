FROM ubuntu:24.04 as build_release

# Please note: Docker is supported as an install method starting with ArchivesSpace v4.0.0, see: https://docs.archivesspace.org/administration/docker/

ENV DEBIAN_FRONTEND=noninteractive \
  JDK_JAVA_OPTIONS="--add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED" \
  TZ=UTC

RUN apt-get update && \
  apt-get -y install --no-install-recommends \
  build-essential \
  git \
  nodejs \
  openjdk-17-jre-headless \
  shared-mime-info \
  wget \
  unzip

COPY . /source

RUN cd /source && \
  if [ `git describe --tags --exact-match --match v* 2>/dev/null` ]; then \
  ARCHIVESSPACE_VERSION="$(git describe --tags --match v*)" ; \
  else \
  ARCHIVESSPACE_VERSION="$(git symbolic-ref -q --short HEAD)-$(git rev-parse --short HEAD)"; \
  fi &&\
  ARCHIVESSPACE_VERSION=${ARCHIVESSPACE_VERSION#"heads/"} && \
  echo "Using version: $ARCHIVESSPACE_VERSION" && \
  ./build/run bootstrap && \
  ./scripts/build_release $ARCHIVESSPACE_VERSION && \
  mv ./*.zip / && \
  cd / && \
  unzip /*.zip -d / && \
  wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.30/mysql-connector-java-8.0.30.jar && \
  cp /mysql-connector-java-8.0.30.jar /archivesspace/lib/

ADD docker-startup.sh /archivesspace/startup.sh
RUN chmod u+x /archivesspace/startup.sh

FROM ubuntu:24.04

LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ENV ARCHIVESSPACE_LOGS=/dev/null \
  ASPACE_GC_OPTS="-XX:+UseG1GC -XX:NewRatio=1" \
  DEBIAN_FRONTEND=noninteractive \
  JDK_JAVA_OPTIONS="--add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED" \
  LANG=C.UTF-8 \
  LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 \
  TZ=UTC

COPY --from=build_release /archivesspace /archivesspace

RUN apt-get update && \
  apt-get -y install --no-install-recommends \
  ca-certificates \
  fontconfig \
  fonts-dejavu-core \
  fonts-dejavu \
  fonts-liberation \
  git \
  libharfbuzz0b \
  libjemalloc2 \
  openjdk-17-jre-headless \
  netbase \
  shared-mime-info \
  wget \
  nodejs \
  unzip && \
  rm -rf /var/lib/apt/lists/* && \
  chown -R 1000:1000 /archivesspace

USER 1000:1000

EXPOSE 8080 8081 8089 8090 8092

HEALTHCHECK --interval=1m --timeout=5s --start-period=5m --retries=2 \
  CMD wget -q --spider http://localhost:8089/ || exit 1

CMD ["/archivesspace/startup.sh"]
