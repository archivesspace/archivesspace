FROM mcr.microsoft.com/vscode/devcontainers/java:11

ARG GECKODRIVER_VERSION \
    MYSQL_CONNECTOR_VERSION \
    SOLR_VERSION

# PERSIST VERSIONS IN ENV FOR REFERENCE
ENV APPCONFIG_DB_URL="jdbc:mysql://localhost:3306/asdev?useUnicode=true&characterEncoding=UTF-8&user=as&password=as123&useSSL=false&allowPublicKeyRetrieval=true" \
    APPCONFIG_SOLR_URL="http://localhost:8983/solr/asdev" \
    ASPACE_TEST_DB_URL="jdbc:mysql://localhost:3306/astest?useUnicode=true&characterEncoding=UTF-8&user=as&password=as123&useSSL=false&allowPublicKeyRetrieval=true" \
    ASPACE_TEST_SOLR_URL="http://localhost:8983/solr/astest" \
    DEBIAN_FRONTEND=noninteractive \
    GECKODRIVER_VERSION=${GECKODRIVER_VERSION} \
    LANG=C.UTF-8 \
    MYSQL_CONNECTOR_VERSION=$MYSQL_CONNECTOR_VERSION \
    SOLR_VERSION=${SOLR_VERSION} \
    TZ=UTC

RUN apt-get update && \
    # INSTALL DEPENDENCIES
    apt-get -y install --no-install-recommends \
        bash-completion \
        build-essential \
        curl \
        firefox-esr \
        git \
        libmariadb-dev \
        mariadb-server \
        mycli \
        python3-pkg-resources \
        python3-setuptools \
        ruby-dev \
        shared-mime-info \
        supervisor \
        wget && \
    gem install bundler && \
    # DOWNLOAD & INSTALL SOLR
    wget https://archive.apache.org/dist/solr/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz && \
    tar xzf solr-$SOLR_VERSION.tgz solr-$SOLR_VERSION/bin/install_solr_service.sh --strip-components=2 && \
    ./install_solr_service.sh solr-$SOLR_VERSION.tgz && \
    # DOWNLOAD GECKODRIVER
    wget https://github.com/mozilla/geckodriver/releases/download/v$GECKODRIVER_VERSION/geckodriver-v$GECKODRIVER_VERSION-linux64.tar.gz && \
    tar -zxvf geckodriver-v$GECKODRIVER_VERSION-linux64.tar.gz && \
    mv geckodriver /usr/local/bin
