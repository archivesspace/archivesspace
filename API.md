# ArchivesSpace REST API
As of 2012-09-18 13:59:19 -0400 the following REST endpoints exist:

	
## /agents 

### Description

Get all agent records

### Parameters

### Returns

	200 -- [(:agent)]

	
## /agents/corporate_entities 

### Description

Create a corporate entity agent

### Parameters

	false <request body> -- The corporate entity to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## /agents/corporate_entities/:agent_id 

### Description

Update a corporate entity agent

### Parameters

	Integer agent_id -- The ID of the agent to update

	false <request body> -- The corporate entity to create

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## /agents/corporate_entities/:id 

### Description

Get a corporate entity by ID

### Parameters

	Integer id -- ID of the corporate entity agent

### Returns

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## /agents/families 

### Description

Create a family agent

### Parameters

	false <request body> -- The family to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## /agents/families/:agent_id 

### Description

Update a family agent

### Parameters

	Integer agent_id -- The ID of the agent to update

	false <request body> -- The family to create

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## /agents/families/:id 

### Description

Get a family by ID

### Parameters

	Integer id -- ID of the family agent

### Returns

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## /agents/people 

### Description

Create a person agent

### Parameters

	false <request body> -- The person to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## /agents/people/:agent_id 

### Description

Update a person agent

### Parameters

	Integer agent_id -- The ID of the agent to update

	false <request body> -- The person to create

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## /agents/people/:id 

### Description

Get a person by ID

### Parameters

	Integer id -- ID of the person agent

### Returns

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## /agents/software 

### Description

Create a software agent

### Parameters

	false <request body> -- The software to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## /agents/software/:agent_id 

### Description

Update a software agent

### Parameters

	Integer agent_id -- The ID of the software to update

	false <request body> -- The software to create

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## /agents/software/:id 

### Description

Get a software by ID

### Parameters

	Integer id -- ID of the software agent

### Returns

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## /repositories 

### Description

Get a list of Repositories

### Parameters

### Returns

	200 -- [(:repository)]

	
## /repositories 

### Description

Create a Repository

### Parameters

	false <request body> -- The repository to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## /repositories/:id 

### Description

Get a Repository by ID

### Parameters

	Integer id -- ID of the repository

### Returns

	200 -- (:repository)
	404 -- {"error":"Repository not found"}

	
## /repositories/:repo_id/accessions 

### Description

Get a list of Accessions for a Repository

### Parameters

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- [(:accession)]

	
## /repositories/:repo_id/accessions 

### Description

Create an Accession

### Parameters

	false <request body> -- The accession to create

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## /repositories/:repo_id/accessions/:accession_id 

### Description

Get an Accession by ID

### Parameters

	Integer accession_id -- The accession ID

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- (:accession)

	
## /repositories/:repo_id/accessions/:accession_id 

### Description

Update an Accession

### Parameters

	Integer accession_id -- The accession ID to update

	false <request body> -- The accession data to update

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## /repositories/:repo_id/archival_objects 

### Description

Create an Archival Object

### Parameters

	false <request body> -- The Archival Object to create

	Integer repo_id -- The Repository ID

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {"error":{"[:resource_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}

	
## /repositories/:repo_id/archival_objects 

### Description

Get a list of Archival Objects for a Repository

### Parameters

	Integer repo_id -- The Repository ID

### Returns

	200 -- [(:archival_object)]

	
## /repositories/:repo_id/archival_objects/:archival_object_id 

### Description

Update an Archival Object

### Parameters

	Integer archival_object_id -- The Archival Object ID to update

	false <request body> -- The Archival Object data to update

	Integer repo_id -- The Repository ID

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}
	409 -- {"error":{"[:resource_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}

	
## /repositories/:repo_id/archival_objects/:archival_object_id 

### Description

Get an Archival Object by ID

### Parameters

	Integer archival_object_id -- The Archival Object ID

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

### Returns

	200 -- (:archival_object)
	404 -- {"error":"ArchivalObject not found"}

	
## /repositories/:repo_id/archival_objects/:archival_object_id/children 

### Description

Get the children of an Archival Object

### Parameters

	Integer archival_object_id -- The Archival Object ID

	Integer repo_id -- The Repository ID

### Returns

	200 -- [(:archival_object)]
	404 -- {"error":"ArchivalObject not found"}

	
## /repositories/:repo_id/resources 

### Description

Create a Resource

### Parameters

	false <request body> -- The resource to create

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## /repositories/:repo_id/resources 

### Description

Get a list of Resources for a Repository

### Parameters

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- [(:resource)]

	
## /repositories/:repo_id/resources/:resource_id 

### Description

Get a Resource

### Parameters

	Integer resource_id -- The ID of the resource to retrieve

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

### Returns

	200 -- (:resource)

	
## /repositories/:repo_id/resources/:resource_id 

### Description

Update a Resource

### Parameters

	Integer resource_id -- The ID of the resource to retrieve

	false <request body> -- The resource to update

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## /repositories/:repo_id/resources/:resource_id/tree 

### Description

Get a Resource tree

### Parameters

	Integer resource_id -- The ID of the resource to retrieve

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- OK

	
## /repositories/:repo_id/resources/:resource_id/tree 

### Description

Update a Resource tree

### Parameters

	Integer resource_id -- The ID of the resource to retrieve

	false <request body> -- A JSON tree representing the modified hierarchy

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## /subjects 

### Description

Create a Subject

### Parameters

	false <request body> -- The subject data to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## /subjects 

### Description

Get a list of Subjects

### Parameters

### Returns

	200 -- [(:subject)]

	
## /subjects/:subject_id 

### Description

Get a Subject by ID

### Parameters

	Integer subject_id -- The subject ID

### Returns

	200 -- (:subject)

	
## /users 

### Description

Create a local user

### Parameters

	String password -- The user's password

	false <request body> -- The user to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## /users/:username/login 

### Description

Log in

### Parameters

	 username -- Your username

	 password -- Your password

### Returns

	200 -- Login accepted
	403 -- Login failed

	
## /vocabularies 

### Description

Get a list of Vocabularies

### Parameters

	String ref_id -- An alternate, externally-created ID for the vocabulary

### Returns

	200 -- [(:vocabulary)]

	
## /vocabularies 

### Description

Create a Vocabulary

### Parameters

	false <request body> -- The vocabulary data to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## /vocabularies/:vocab_id 

### Description

Update a Vocabulary

### Parameters

	Integer vocab_id -- The vocabulary ID to update

	false <request body> -- The vocabulary data to update

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## /vocabularies/:vocab_id 

### Description

Get a Vocabulary by ID

### Parameters

	Integer vocab_id -- The vocabulary ID

### Returns

	200 -- OK

	
## /vocabularies/:vocab_id/terms 

### Description

Get a list of Terms for a Vocabulary

### Parameters

	Integer vocab_id -- The vocabulary ID

### Returns

	200 -- [(:term)]



