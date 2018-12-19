---
title: Search indexing
layout: en
permalink: /user/search-indexing/
---
The ArchivesSpace system uses Solr for its full-text search.  As
records are added/updated/deleted by the backend, the corresponding
changes are made to the Solr index to keep them (roughly)
synchronized.

Keeping the backend and Solr in sync is the job of the "indexer", a
separate process that runs in the background and watches for record
updates.  The indexer operates in two modes simultaneously:

  * The periodic mode polls the backend to get a list of records that
    were added/modified/deleted since it last checked.  These changes
    are propagated to the Solr index.  This generally happens every 30
    to 60 seconds (and is configurable).
  * The real-time mode responds to updates as they happen, applying
    changes to Solr as soon as they're applied to the backend.  This
    aims to reflect updates within the search indexes in milliseconds
    or seconds.

The two modes of operation overlap somewhat, but they serve different
purposes.  The periodic mode ensures that records are never missed due
to transient failures, and will bring the indexes up to date even if
the indexer hasn't run for quite some time--even creating them from
scratch if necessary.  This mode is also used for indexing updates
made by bulk import processes and other updates that don't need to be
reflected in the indexes immediately.

The real-time indexer mode attempts to apply updates to the index much
more quickly.  Rather than polling, it performs a `GET` request
against the `/update-feed` endpoint of the backend.  This endpoint
returns any records that were updated since the last time it was asked
and, most importantly, it leaves the request hanging if no records
have changed.

By calling this endpoint in a loop, the real-time indexer spends most
of its time sitting around waiting for something to happen.  The
moment a record is updated, the already-pending request to the
`/update-feed` endpoint yields the updated record, which is sent to
Solr and indexed immediately.  This avoids the delays associated with
polling and keeps indexing latency low where it matters.  For example,
newly created records should appear in the browse list by the time a
user views it.
