---
title: Re-creating indexes
layout: en
permalink: /user/re-creating-indexes/
---
There are two strategies for reindexing ArchivesSpace:

- soft reindex
- full reindex

## Soft reindex

A soft reindex updates the existing documents in Solr without directly
touching the actual index documents on the filesystem. This can be done
while the system is running and is suitable for most use cases.

There are two common ways to perform a soft reindex:

1. Delete indexer state files

ArchivesSpace keeps track of what has been indexed by using the files
under `data/indexer_state` and `data/indexer_pui_state` (for the PUI).

If these files are missing, the indexer assumes that nothing has been
indexed and reindexes everything. To force ArchivesSpace to reindex all
records, just delete the files in `/path/to/archivesspace/data/indexer_state`
and `/path/to/archivesspace/data/indexer_pui_state`.

You also can do this selectively by record type, for example, to reindex
accessions in repository 2 delete the file called `2_accession.dat`.

2. Bump `system_mtime` values in the database

If you update a record's `system_mtime` it becomes eligible for reindexing.

```sql
#reindex all resources
UPDATE resource SET system_mtime = NOW();
#reindex resource 1
UPDATE resource SET system_mtime = NOW() WHERE id = 1;
```

## Full reindex

A full reindex is a complete rebuild of the index from the database. This
may be required if you are having indexer issues, in the case of index
corruption, or if called for by an upgrade owing to changes in ArchivesSpace's
Solr configuration.

To perform a full reindex:

- Shutdown ArchivesSpace
- Delete these directories:
  - `rm -rf /path/to/archivesspace/data/indexer_state/`
  - `rm -rf /path/to/archivesspace/data/indexer_pui_state/`
  - `rm -rf /path/to/archivesspace/data/solr_index/`
- Restart ArchivesSpace

You can watch the [Tips for indexing ArchivesSpace](https://www.youtube.com/watch?v=yFJ6yAaPa3A) youtube video to see these steps performed.

---
