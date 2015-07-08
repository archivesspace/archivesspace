---
title: Re-creating indexes 
layout: en
permalink: /user/re-creating-indexes/ 
---

ArchivesSpace keeps track of what has been indexed by using the files
under `data/indexer_state`.  If these files are missing, the indexer
assumes that nothing has been indexed and reindexes everything.

To force ArchivesSpace to reindex all records, just delete the
directory `/path/to/archivesspace/data/indexer_state`.  Since the
indexing process is cumulative, there's no harm in indexing the same
document multiple times.


