---
title: You may have other plugins 
layout: en
permalink: /user/you-may-have-other-plugins/ 
---
AppConfig[:plugins] = ['local', 'newrelic']

AppConfig[:newrelic_key] = "enteryourkeyhere"
AppConfig[:newrelic_app_name] = "ArchivesSpace"
```

- Install the New Relic agent library by initializing the plugin:

     # For Linux/OSX
     $ scripts/initialize-plugin.sh newrelic
     
     # For Windows
     % scripts\initialize-plugin.bat newrelic
 
- Start, or restart ArchivesSpace to pick up the configuration.

  Within a few minutes the application should be visible in the New Relic dashboard with data being collected.

---
