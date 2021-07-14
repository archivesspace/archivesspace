FROM solr:8.8
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

COPY * /archivesspace/

# ASPACE REQUIRES THESE LIBS (WHICH ARE INCL. IN THE 8.8 IMG):
# /opt/solr/dist/solr-analysis-extras-${VERSION}.jar
# /opt/solr/contrib/analysis-extras/lucene-libs/lucene-analyzers-icu-${VERSION}.jar
# /opt/solr/contrib/analysis-extras/lib/icu4j-*.jar

USER root
RUN mv /archivesspace/schema-8.8.min.xml /archivesspace/schema.xml && \
    mv /archivesspace/solrconfig-8.8.min.xml /archivesspace/solrconfig.xml
USER solr
