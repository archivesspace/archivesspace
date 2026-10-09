# Java runtime used for both stages. Build a Java 21 image with: --build-arg JAVA_VERSION=21
ARG JAVA_VERSION=25
ARG MYSQL_CONNECTOR_VERSION=9.7.0

FROM ubuntu:resolute-20260927 AS build_release

ARG JAVA_VERSION
ARG MYSQL_CONNECTOR_VERSION

# Please note: Docker is supported as an installation method starting with ArchivesSpace v4.0.0, see: https://docs.archivesspace.org/administration/docker/

ENV DEBIAN_FRONTEND=noninteractive \
  JDK_JAVA_OPTIONS="--add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --enable-native-access=ALL-UNNAMED" \
  TZ=UTC

RUN apt-get update && \
  apt-get -y install --no-install-recommends \
  build-essential \
  git \
  nodejs \
  openjdk-${JAVA_VERSION}-jre-headless \
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
  wget https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_CONNECTOR_VERSION}/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar && \
  cp /mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar /archivesspace/lib/

ADD docker-startup.sh /archivesspace/startup.sh
RUN chmod u+x /archivesspace/startup.sh

FROM ubuntu:resolute-20260927

ARG JAVA_VERSION

LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ENV ARCHIVESSPACE_LOGS=/dev/null \
  ASPACE_GC_OPTS="-XX:+UseG1GC -XX:NewRatio=1" \
  ASPACE_JAVA_VERSION=${JAVA_VERSION} \
  DEBIAN_FRONTEND=noninteractive \
  JDK_JAVA_OPTIONS="--add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --enable-native-access=ALL-UNNAMED" \
  LANG=C.UTF-8 \
  LD_PRELOAD="/usr/local/lib/libjemalloc.so" \
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
  openjdk-${JAVA_VERSION}-jre-headless \
  netbase \
  shared-mime-info \
  wget \
  nodejs \
  unzip && \
  rm -rf /var/lib/apt/lists/* && \
  ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
  chown -R 1000:1000 /archivesspace

USER 1000:1000

EXPOSE 8080 8081 8089 8090 8092

HEALTHCHECK --interval=1m --timeout=5s --start-period=5m --retries=2 \
  CMD wget -q --spider http://localhost:8089/ || exit 1

CMD ["/archivesspace/startup.sh"]
