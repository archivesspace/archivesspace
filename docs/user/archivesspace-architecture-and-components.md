---
title: ArchivesSpace architecture and components
layout: en
permalink: /user/archivesspace-architecture-and-components/
---
ArchivesSpace is divided into several components: the backend, which
exposes the major workflows and data types of the system via a
REST API, a staff interface, a public interface, and a search system,
consisting of Solr and an indexer application.

These components interact by exchanging JSON data.  The format of this
data is defined by a class called JSONModel.

* [JSONModel -- a validated ArchivesSpace record](./jsonmodel.md)
* [The ArchivesSpace backend](./backend)
* [Background Jobs](./jobs)
* [Search indexing](./search)
* [The ArchivesSpace public user interface](./public))
* [OAI-PMH interface](./oai-pmg)
