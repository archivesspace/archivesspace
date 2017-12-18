---
title: Configuring OAI-PMH 
layout: en
permalink: /user/configuring-oai-pmh/ 
---

A starter OAI-PMH interface for ArchivesSpace allowing other systems to harvest your records is included in version 2.1.0. Additional features and functionality will be added in later releases.

Information on configuring the OAI-PMH is available at https://github.com/archivesspace/archivesspace#configuring-oai-pmh. By default, it runs on port 8082. A sample request page is available at http://localhost:8082/sample. (To access it, make sure that you have set the AppConfig[:oai_proxy_url] appropriately.)

The system provides responses to a number of standard OAI-PMH requests, including GetRecord, Identify, ListIdentifiers, ListMetadataFormats, ListRecords, and ListSets. Unpublished and suppressed records and elements are not included in any of the OAI-PMH responses.

Some responses require the URL parameter metadataPrefix. There are five different metadata responses available:

  EAD	                  oai_ead (resources in EAD)
  Dublin Core	          oai_dc (archival objects and resources in Dublin Core)
  extended DCMI Terms	  oai_dcterms (archival objects and resources in DCMI Metadata Terms format)
  MARC	                oai_marc (archival objects and resources in MARC)
  MODS	                oai_mods (archival objects and resources in MODS)

The EAD response for resources and MARC response for resources and archival objects use the mappings from the built-in exporter for resources. The DC, DCMI terms, and MODS responses for resources and archival objects use mappings suggested by the community.

Here are some example URLs and other information for these requests:

**GetRecord** – needs a record identifier and metadataPrefix

  	http://localhost:8082/oai?verb=GetRecord&identifier=oai:archivesspace//repositories/2/resources/138&metadataPrefix=oai_ead

**Identify**

  	http://localhost:8082/oai?verb=Identify

**ListIdentifiers** – needs a metadataPrefix

  	http://localhost:8082/oai?verb=ListIdentifiers&metadataPrefix=oai_dc

**ListMetadataFormats**

  	http://localhost:8082/oai?verb=ListMetadataFormats

**ListRecords** – needs a metadataPrefix

	http://localhost:8082/oai?verb=ListRecords&metadataPrefix=oai_dcterms

**ListSets**

	http://localhost:8082/oai?verb=ListSets

Harvesting the ArchivesSpace OAI-PMH server without specifying a set will yield all published records across all repositories.
Predefined sets can be accessed using the set parameter. In order to retrieve records from sets include a set parameter in the URL and the DC metadataPrefix, such as "&set=collection&metadataPrefix=oai_dc". These sets can be from configured sets as shown above or from the following levels of description:

  Class	      class
  Collection	collection
  File	      file
  Fonds	      fonds
  Item	      item
  Other_Level	otherlevel
  Record_Group	recordgrp
  Series	    series
  Sub-Fonds	  subfonds
  Sub-Group	  subgrp
  Sub-Series	 subseries

In addition to the sets based on level of description, you can define sets based on repository codes and/or sponsors in the config/config.rb file:

	AppConfig[:oai_sets] = {
  	'repository_set' => {
    	:repo_codes => ['hello626'],
    	:description => "A set of one or more repositories",
  	},

  	'sponsor_set' => {
    	:sponsors => ['The_Sponsor'],
    	:description => "A set of one or more sponsors",
  	},
	}

The interface implements resumption tokens for pagination of results. As an example, the following URL format should be used to page through the results from a ListRecords request:

  	http://localhost:8082/oai?verb=ListRecords&metadataPrefix=oai_ead

using the resumption token:

  	http://localhost:8082/oai?verb=ListRecords&resumptionToken=eyJtZXRhZGF0YV9wcmVmaXgiOiJvYWlfZWFkIiwiZnJvbSI6IjE5NzAtMDEtMDEgMDA6MDA6MDAgVVRDIiwidW50aWwiOiIyMDE3LTA3LTA2IDE3OjEwOjQxIFVUQyIsInN0YXRlIjoicHJvZHVjaW5nX3JlY29yZHMiLCJsYXN0X2RlbGV0ZV9pZCI6MCwicmVtYWluaW5nX3R5cGVzIjp7IlJlc291cmNlIjoxfSwiaXNzdWVfdGltZSI6MTQ5OTM2MTA0Mjc0OX0=

Note: you do not use the metadataPrefix when you use the resumptionToken

The ArchivesSpace OAI-PMH server supports persistent deletes, so harvesters will be notified of any records that were deleted since
they last harvested.

```Mixed content is removed from Dublin Core, dcterms, MARC, and MODS field outputs in the OAI-PMH response (e.g., a scope note mapped to a DC description field would not include <p>, <abbr>, <address>, <archref>, <bibref>, <blockquote>, <chronlist>, <corpname>, <date>, <emph>, <expan>, <extptr>, <extref>, <famname>, <function>, <genreform>, <geogname>, <lb>, <linkgrp>, <list>, <name>, <note>, <num>, <occupation>, <origination>, <persname>, <ptr>, <ref>, <repository>, <subject>, <table>, <title>, <unitdate>, <unittitle>).```

The component level records include inherited data from superior hierarchical levels of the finding aid. Element inheritance is determined by institutional system configuration (editable in the config/config.rb file) as implemented for the Public User Interface.

ARKs have not yet been implemented, pending more discussion of how they should be formulated.

