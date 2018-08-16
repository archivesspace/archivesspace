# NYU Archivesspace DO Plugin
***


This is an ArchivesSpace plugin that extends the ArchivesSpace API to allow real time Digital Object look ups.

This plugin was developed against ArchivesSpace v1.5.1 by [Hudson Molonglo](https://github.com/hudmol/composers) for New York University with generous funding from the Mellon Foundation.

**How to Install**

1. Download latest release at: https://github.com/NYULibraries/Archivesspace-DO-Plugin/releases 

2. Uncompress the directory and copy to your archivesspace plugins directory, with the name 'nyudo'

3. Enable the plugin by editing the file in config/config.rb: AppConfig[:plugins] = ['some_exisiting plugin', 'nyudo']

4. Add a proxy for your backend url in config/config.rb: AppConfig[:backend_proxy_url] = "http://example.com:8089"

Your archivesspace should now have 3 extra endpoints: /plugins/nyudo/repositories/:repo_id/archiveit/:resource_id, /plugins/nyudo/repositories/:repo_id/sumary/:resource_id, and /plugins/nyudo/repositories/:repo_id/detailed/:component_id

**Authentication**

The endpoints are configured to require an authenticated session from Archivesspace for a user account with read-repository permissions. This can be configured to a different permission setting, or no perissions at all, by modifying the nyudo.rb from the Controllers directory, and changing the argument to the permissions methods: ".permissions([:view_repository])"

**Archiveit Integration**

The API includes an endpoint, /plugins/nyudo/repositories/:repository_id/archiveit/:resource_id, that generates a json response that can be consumed by Archive-It. More information on this integration can be found at https://github.com/NYULibraries/Archivesspace-DO-Plugin/wiki/Archive-It-Integration 

**example**

A URL can be created that passes the repository and resource identifiers for a resource described in archivesspace as a parameter to the archiveit endpoint:

http://demo.nyu.edu:8089/plugins/nyudo/repositories/2/archiveit/mss.460

The endpoint will generate a json response that can be consumed by Archive-It by entering the the url in the 'Related Archival Materials' field in the metadata for a seed url archived in Archive-It. 

{ <br/> 
  "title":"Adele Fournet Papers on the Bit Rosie Web Series",<br/>
  "extent":"33 Digital Objects",<br/>
  "display_url":"http://demo.nyu.edu:8089/plugins/nyudo/repositories/2/summary/mss.460"<br/>
}<br/>

**Endpoint Summary**

The Archivesspace DO plugin adds three GET endpoints to the 

GET /plugins/nyudo/repositories/:repository_id/archiveit/:resource_id<br/>
Provides a json response with basic data about a collection for integration with Archive-It. More information on the integration can be found here: https://github.com/NYULibraries/Archivesspace-DO-Plugin/wiki/Archive-It-Integration<br/>

GET /plugins/nyudo/repositories/:repository_id/summary/:resource_id<br/>
Provides a json response with data about a resources and a summary of digital objects that are described as part of the resource<br/>

GET /plugins/nyudo/repositories/:repository_id/detailed/:resource_id<br/>
Provides a json response with information about a digital object and parent archival object<br/>

**Demo Application**

A demo application that consumes the data from the API is available at: [https://github.com/NYULibraries/Composers-API-Demo](https://github.com/NYULibraries/Composers-API-Demo)
