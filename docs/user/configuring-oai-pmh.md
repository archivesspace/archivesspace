---
title: Configuring OAI-PMH 
layout: en
permalink: /user/configuring-oai-pmh/ 
---

ArchivesSpace provides an OAI-PMH server to allow others to harvest
your records.  You can access this from your browser by hitting:

  http://localhost:8082?verb=Identify

## Supported metadata formats

The following metadata formats are supported:

  * oai_dc -- Archival Objects expressed in Dublin Core

  * oai_dcterms -- Archival Objects expressed in DCMI Metadata Terms format

  * oai_ead -- Resources expressed in EAD

  * oai_mods -- Archival Objects expressed in MODS

  * oai_marc -- Archival Objects expressed in MARCXML

You can query the list of supported metadata formats using OAI-PMH
itself by accessing:

  http://localhost:8082?verb=ListMetadataFormats

## OAI sets

Harvesting the ArchivesSpace OAI-PMH server without specifying a set
will yield all published records across all repositories.  However,
you can configure OAI sets to limit harvests by repository and/or
finding aid sponsor.  See the `AppConfig[:oai_sets]` option in your
`config.rb` file for an example of how to do this (or view the default
configuration online here:
https://github.com/archivesspace/archivesspace/blob/master/common/config/config-defaults.rb).

The ArchivesSpace also provides some predefined OAI sets based on the
Level Of Description field of records.  This allows harvesters to
target (for example) only Series level records, or only files.  You
can see the list of available sets by accessing:

  http://localhost:8082?verb=ListSets

## Deletes

The ArchivesSpace OAI-PMH server supports persistent deletes, so
harvesters will be notified of any records that were deleted since
they last harvested.


## Configuring OAI sets

In addition to the standard OAI sets, you can define your own sets
based on a combination of repository and finding aid sponsor.


