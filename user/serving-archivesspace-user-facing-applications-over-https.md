---
title: Serving ArchivesSpace user-facing applications over HTTPS 
layout: en
permalink: /user/serving-archivesspace-user-facing-applications-over-https/ 
---
==============================================================

This document describes a simple approach for those wishing to install
ArchivesSpace in such a manner that all end-user requests (i.e., URLs)
are served over HTTPS rather than HTTP.

The configuration described in this document is one possible approach,
and to keep things simple the following are assumed:

  * ArchivesSpace is running on a single Linux server

  * The server is running the Apache 2.2+ webserver

  * You have obtained an SSL certificate and key from an authority

Unless otherwise stated, it is assumed that you have root access on
your machines, and all commands are to be run as root (or with sudo).


