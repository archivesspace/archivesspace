FROM solr:8.10
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ENV ARCHIVESSPACE_CONFIGSET_PATH=/opt/solr/server/solr/configsets/archivesspace/conf

USER root

RUN mkdir -p $ARCHIVESSPACE_CONFIGSET_PATH
COPY * $ARCHIVESSPACE_CONFIGSET_PATH/
RUN chown -R solr:solr $ARCHIVESSPACE_CONFIGSET_PATH

# ASPACE REQUIRES THESE LIBS (WHICH ARE INCL. IN THE v8 IMG):
# /opt/solr/dist/solr-analysis-extras-${VERSION}.jar
# /opt/solr/contrib/analysis-extras/lucene-libs/lucene-analyzers-icu-${VERSION}.jar
# /opt/solr/contrib/analysis-extras/lib/icu4j-*.jar

USER solr
