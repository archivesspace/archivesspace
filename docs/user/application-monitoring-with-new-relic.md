---
title: Application monitoring with New Relic 
layout: en
permalink: /archivesspace/user/application-monitoring-with-new-relic/ 
---
=====================================

[New Relic](http://newrelic.com/) is an application performance monitoring tool (amongst other things).

**To use with ArchivesSpace you must:**

- Signup for an account at newrelic (there is a free tier and paid plans)

- Edit config.rb to:
  - activate the `newrelic` plugin
  - add the New Relic license key
  - add an application name to identify the ArchivesSpace instance in the New Relic dashboard

For example, in config.rb:

```
