FROM solr:6.6
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

COPY * /archivesspace/

ENV ICU4J_VERSION=65_1 \
    SOLR_VERSION=6.6
USER root
RUN mv /archivesspace/schema-$SOLR_VERSION.xml /archivesspace/schema.xml && \
    mv /archivesspace/solrconfig-$SOLR_VERSION.xml /archivesspace/solrconfig.xml
USER solr
RUN wget -O contrib/analysis-extras/lib/icu4j-$ICU4J_VERSION.jar \
    https://github.com/unicode-org/icu/releases/download/release-65-1/icu4j-$ICU4J_VERSION.jar
