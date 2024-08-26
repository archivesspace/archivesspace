FROM mcr.microsoft.com/vscode/devcontainers/java:11

ARG GECKODRIVER_VERSION=0.30.0
ARG MYSQL_CONNECTOR_VERSION=

COPY . /archivesspace
WORKDIR /archivesspace

RUN echo 'Downloading Packages' && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      bash-completion \
      build-essential \
      ca-certificates \
      curl \
      firefox-esr \
      git \
      libmariadb-dev \
      mariadb-server \
      mycli \
      netbase \
      npm \
      openjdk-17-jre-headless \
      python3-pkg-resources \
      python3-setuptools \
      ruby-dev \
      shared-mime-info \
      supervisor \
      unzip \
      vim \
      wget \
    && \
    curl https://sh.rustup.rs -sSf | bash -s -- -y && \
    gem install bundler rubocop solargraph && \
    mkdir -p /opt && cd /opt && \
    git clone https://github.com/mozilla/geckodriver.git && cd geckodriver  && \
    git checkout v${GECKODRIVER_VERSION} && \
    /root/.cargo/bin/cargo build && \
    mv ./target/debug/geckodriver /usr/local/bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/log/supervisor && \
    cd /archivesspace/common/lib && \
    wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar && \
    cd - && \
    ./build/run bootstrap

EXPOSE 3000 3001 4567

CMD ["/usr/bin/supervisord", "-c", "/archivesspace/supervisord/archivesspace.conf"]
