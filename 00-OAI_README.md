Just some quick notes on the current state of OAI for folks who want
to take it for a spin.

Right now, you can access the OAI endpoint by hitting the '/oai' URI
on the backend with a GET request.  In the future we'll have a
dedicated port to proxy requests through to this endpoint (so that
people don't need to open up their ArchivesSpace API just to expose an
OAI repository).

There are some configuration options you can set, but it should work
without modification for simple tests.  See the options beginning with
`:oai_` in `common/config/config-defaults.rb` for these.

Once you have an ArchivesSpace instance up and running with some
(published) records, you can run a harvest.  I've been testing with
`pyoaiharvest`
(https://github.com/vphill/pyoaiharvester/blob/master/pyoaiharvest.py)
which is nice and quick to get running.  With that, running a harvest
looks like:

    # Dublin Core
    python pyoaiharvest.py -l 'http://localhost:8089/oai' -m oai_dc -o oai_dc.xml

    # DCMI Terms
    python pyoaiharvest.py -l 'http://localhost:8089/oai' -m oai_dcterms -o oai_dcterms.xml

    # EAD
    python pyoaiharvest.py -l 'http://localhost:8089/oai' -m oai_ead -o oai_ead.xml
