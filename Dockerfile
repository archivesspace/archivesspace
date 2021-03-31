FROM ubuntu:20.04 as build_release

# Please note: Docker is not supported as an install method.
# Docker configuration is being used for internal purposes only.
# Use of Docker by anyone else is "use at your own risk".
# Docker related files may be updated at anytime without
# warning or presence in release notes.

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
      build-essential \
      git \
      openjdk-8-jre-headless \
      shared-mime-info \
      wget \
      unzip

COPY . /source

RUN cd /source && \
    ARCHIVESSPACE_VERSION=${SOURCE_BRANCH:-`git symbolic-ref -q --short HEAD || git describe --tags --match v*`} && \
    ARCHIVESSPACE_VERSION=${ARCHIVESSPACE_VERSION#"heads/"} && \
    echo "Using version: $ARCHIVESSPACE_VERSION" && \
    ./scripts/build_release $ARCHIVESSPACE_VERSION && \
    mv ./*.zip / && \
    cd / && \
    unzip /*.zip -d / && \
    wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar && \
    cp /mysql-connector-java-8.0.23.jar /archivesspace/lib/

ADD docker-startup.sh /archivesspace/startup.sh
RUN chmod u+x /archivesspace/startup.sh

FROM ubuntu:20.04

LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ENV ARCHIVESSPACE_LOGS=/dev/null \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC

COPY --from=build_release /archivesspace /archivesspace

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
      ca-certificates \
      openjdk-8-jre-headless \
      netbase \
      shared-mime-info \
      wget \
      unzip && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g 1000 archivesspace && \
    useradd -l -M -u 1000 -g archivesspace archivesspace && \
    chown -R archivesspace:archivesspace /archivesspace

USER archivesspace

EXPOSE 8080 8081 8089 8090 8092

HEALTHCHECK --interval=1m --timeout=5s --start-period=5m --retries=2 \
  CMD wget -q --spider http://localhost:8089/ || exit 1

CMD ["/archivesspace/startup.sh"]
