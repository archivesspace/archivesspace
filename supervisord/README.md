# Using Supervisord for development

[Supervisord](http://supervisord.org/) can simultaneously launch the ArchivesSpace development servers.
This is entirely optional and just for developer convenience.

## Setup

From within the ArchivesSpace source directory:

```
./build/run bootstrap # if needed, as usual

[sudo] pip install supervisor supervisor-stdout

# run all of the services
supervisord -c supervisord/archivesspace.conf

# run in api mode (backend + indexer / solr only)
supervisord -c supervisord/api.conf

# run just the backend (useful for trying out endpoints that don't require Solr)
supervisord -c supervisord/backend.conf
```

To stop supervisord: `Ctrl-c`.

---
