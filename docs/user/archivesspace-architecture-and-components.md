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

* [JSONModel -- a validated ArchivesSpace record](https://archivesspace.github.io/archivesspace/user/jsonmodel----a-validated-archivesspace-record/)
* [The ArchivesSpace backend](https://archivesspace.github.io/archivesspace/user/the-archivesspace-backend/)
* [Background Jobs](https://archivesspace.github.io/archivesspace/user/background-jobs/)
* [Working with the ArchivesSpace API](https://archivesspace.github.io/archivesspace/user/working-with-the-archivesspace-api/)
* [Search indexing](https://archivesspace.github.io/archivesspace/user/search-indexing/)
* [The ArchivesSpace public user interface](https://archivesspace.github.io/archivesspace/user/the-archivesspace-public-user-interface/)
* [OAI-PMH interface](https://archivesspace.github.io/archivesspace/user/oai-pmh-interface/)
