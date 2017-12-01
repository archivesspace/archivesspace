FROM openjdk:8-jre
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ENV LANG=C.UTF-8

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
    ./scripts/build_release -g && \
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

CMD ["/startup.sh"]
