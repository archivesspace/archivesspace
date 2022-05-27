FROM maven:3.8.5-openjdk-11

COPY . /archivesspace
WORKDIR /archivesspace

RUN echo 'Downloading Packages' && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      netbase \
      npm \
      openjdk-11-jre-headless \
      shared-mime-info \
      supervisor \
      unzip \
      vim \
      wget \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/log/supervisor && \
    cd /archivesspace/common/lib && \
    wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar && \
    cd - && \
    ./build/run bootstrap

EXPOSE 8080 8081 8089 8090 8092

CMD ["/usr/bin/supervisord", "-c", "/archivesspace/supervisord/archivesspace.conf"]
