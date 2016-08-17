FROM ubuntu:xenial
MAINTAINER Mark Cooper <mark.c.cooper@outlook.com>
# LOCAL BUILD COMMAND:
# docker build --no-cache=true -t archivesspace:source .

ENV ASPACE_PUBLIC_DEV=false \
LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8 \
  MYSQL_CONNECTOR_VERSION=${MYSQL_CONNECTOR_VERSION:-5.1.39}

COPY docker/locale /etc/default/locale

RUN locale-gen en_US.UTF-8 && \
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales && \
# ADD MULTIVERSE FOR JASPER MS FONTS AND ACCEPT THE LICENSE \
echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial multiverse\n\
deb-src http://us.archive.ubuntu.com/ubuntu/ xenial multiverse\n\
deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates multiverse\n\
deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-updates multiverse\n'\
>> /etc/apt/sources.list && \
  echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
  echo "msttcorefonts msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
  # INSTALL REQUIRED PACKAGES (FOR RELEASE AND SOURCE VERSIONS)
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
  git \
  mysql-client \
  msttcorefonts \
  openjdk-8-jdk-headless \
  openjdk-8-jre-headless \
  wget \
  unzip && \
  rm -rf /var/lib/apt/lists/*

ADD . /source

RUN cd /source && \
  cp docker/setup.sh /setup.sh && \
  # PROCESS BUILD
  ./scripts/build_release -t && \
  mv ./*.zip / && \
  rm -rf /source && \
  # UNPACK BUILD \
  cd / && \
  unzip /*.zip -d / && \
  rm /*.zip && \
  rm -rf /archivesspace/plugins/* && \
  chmod 755 /archivesspace/archivesspace.sh && \
  # FINALIZE SETUP \
  wget http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.39/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar && \
  cp /mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar /archivesspace/lib/ && \
  chmod u+x /*.sh

ADD docker/config.rb /archivesspace/config/config.rb

EXPOSE 8080 8081 8089 8090

CMD ["/setup.sh"]
