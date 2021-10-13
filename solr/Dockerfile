FROM solr:8.10
LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

COPY * /archivesspace/

# ASPACE REQUIRES THESE LIBS (WHICH ARE INCL. IN THE v8 IMG):
# /opt/solr/dist/solr-analysis-extras-${VERSION}.jar
# /opt/solr/contrib/analysis-extras/lucene-libs/lucene-analyzers-icu-${VERSION}.jar
# /opt/solr/contrib/analysis-extras/lib/icu4j-*.jar

USER solr
