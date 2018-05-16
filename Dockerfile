FROM openjdk:8-jre
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ENV ARCHIVESSPACE_LOGS=/dev/null \
    LANG=C.UTF-8

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
      git \
      mysql-client \
      sendmail \
      wget \
      unzip && \
      rm -rf /var/lib/apt/lists/*

COPY . /source

RUN cd /source && \
    export ARCHIVESSPACE_VERSION=${SOURCE_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)} && \
    ./scripts/build_release $ARCHIVESSPACE_VERSION && \
    mv ./*.zip / && \
    rm -rf /source && \
    cd / && \
    unzip /*.zip -d / && \
    rm /*.zip && \
    rm -rf /archivesspace/plugins/* && \
    chmod 755 /archivesspace/archivesspace.sh && \
    wget http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.39/mysql-connector-java-5.1.39.jar && \
    cp /mysql-connector-java-5.1.39.jar /archivesspace/lib/

# FINALIZE SETUP
ADD docker-startup.sh /startup.sh
RUN chmod u+x /*.sh

EXPOSE 8080 8081 8089 8090 8092
HEALTHCHECK --interval=1m --timeout=5s --start-period=5m --retries=2 \
  CMD curl -f http://localhost:8089/ || exit 1

CMD ["/startup.sh"]
