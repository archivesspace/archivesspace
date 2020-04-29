---
title: Running ArchivesSpace with external Solr
layout: en
permalink: /user/running-archivesspace-with-external-solr/
---
Assuming you've unzipped a fresh new release there are a couple of steps to take:

## Setup a Solr core

On the Solr server make a core available for ArchivesSpace. Copy the solr files from the ArchivesSpace source into the core's conf directory and enable it:

[Solr Directory](https://github.com/archivesspace/archivesspace/tree/master/solr)

## Disable the embedded server Solr instance

Edit the ArchivesSpace config.rb file:

```
AppConfig[:enable_solr] = false
```

Note that doing this means that you will have to backup Solr manually.

## Set the Solr url

This config setting should point to your Solr instance:

```
AppConfig[:solr_url] = "http://solr.somewhere.org:8983/solr"
```

Include path if required:

```
AppConfig[:solr_url] = "http://solr.somewhere.org:8983/solr/archivesspace"
```

---

You should monitor the ArchivesSpace logs and Solr to ensure that the indexer application is connecting to the external Solr instance.

---
