FROM solr:9.4.1
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ENV ARCHIVESSPACE_CONFIGSET_PATH=/opt/solr/server/solr/configsets/archivesspace/conf
ENV SOLR_MODULES=analysis-extras

USER root

RUN mkdir -p $ARCHIVESSPACE_CONFIGSET_PATH
COPY * $ARCHIVESSPACE_CONFIGSET_PATH/
RUN chown -R solr:solr $ARCHIVESSPACE_CONFIGSET_PATH

# ASPACE REQUIRES THESE LIBS (WHICH ARE INCL. IN THE v9 IMG):
# /opt/solr/modules/analysis-extras/lib/solr-analysis-extras-*.jar
# /opt/solr/modules/analysis-extras/lib/lucene-analysis-icu-*.jar
# /opt/solr/modules/analysis-extras/lib/icu4j-*.jar

USER solr
