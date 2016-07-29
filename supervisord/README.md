## Using Supervisord for development

Supervisord can be used to simultaneously launch the ArchivesSpace development servers. This is entirely optional and just for developer convenience.

**Setup**

From within the ArchivesSpace source directory:

```
./build/run bootstrap # if needed, as usual

[sudo] pip install supervisor supervisor-stdout
supervisord -c supervisord/archivesspace.conf
```

Now wait for all of the services to start. The `archivesspace.conf` file runs all of the servers but you can also run in `api` mode (backend and indexer only, no user interfaces):

```
supervisord -c supervisord/api.conf
```

To stop supervisord: `Ctrl-c`.

---