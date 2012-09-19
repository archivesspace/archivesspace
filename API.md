# ArchivesSpace REST API
As of 2012-09-18 20:55:42 -0400 the following REST endpoints exist:

	
## GET /agents 

### Description

Get all agent records

### Parameters

### Returns

	200 -- [(:agent)]

	
## POST /agents/corporate_entities 

### Description

Create a corporate entity agent

### Parameters

	JSONModel(:agent_corporate_entity) <request body> -- The corporate entity to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /agents/corporate_entities/:agent_id 

### Description

Update a corporate entity agent

### Parameters

	Integer agent_id -- The ID of the agent to update

	JSONModel(:agent_corporate_entity) <request body> -- The corporate entity to create

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /agents/corporate_entities/:id 

### Description

Get a corporate entity by ID

### Parameters

	Integer id -- ID of the corporate entity agent

### Returns

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## POST /agents/families 

### Description

Create a family agent

### Parameters

	JSONModel(:agent_family) <request body> -- The family to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /agents/families/:agent_id 

### Description

Update a family agent

### Parameters

	Integer agent_id -- The ID of the agent to update

	JSONModel(:agent_family) <request body> -- The family to create

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /agents/families/:id 

### Description

Get a family by ID

### Parameters

	Integer id -- ID of the family agent

### Returns

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## POST /agents/people 

### Description

Create a person agent

### Parameters

	JSONModel(:agent_person) <request body> -- The person to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /agents/people/:agent_id 

### Description

Update a person agent

### Parameters

	Integer agent_id -- The ID of the agent to update

	JSONModel(:agent_person) <request body> -- The person to create

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /agents/people/:id 

### Description

Get a person by ID

### Parameters

	Integer id -- ID of the person agent

### Returns

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## POST /agents/software 

### Description

Create a software agent

### Parameters

	JSONModel(:agent_software) <request body> -- The software to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /agents/software/:agent_id 

### Description

Update a software agent

### Parameters

	Integer agent_id -- The ID of the software to update

	JSONModel(:agent_software) <request body> -- The software to create

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /agents/software/:id 

### Description

Get a software by ID

### Parameters

	Integer id -- ID of the software agent

### Returns

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## GET /repositories 

### Description

Get a list of Repositories

### Parameters

### Returns

	200 -- [(:repository)]

	
## POST /repositories 

### Description

Create a Repository

### Parameters

	JSONModel(:repository) <request body> -- The repository to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## GET /repositories/:id 

### Description

Get a Repository by ID

### Parameters

	Integer id -- ID of the repository

### Returns

	200 -- (:repository)
	404 -- {"error":"Repository not found"}

	
## GET /repositories/:repo_id/accessions 

### Description

Get a list of Accessions for a Repository

### Parameters

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- [(:accession)]

	
## POST /repositories/:repo_id/accessions 

### Description

Create an Accession

### Parameters

	JSONModel(:accession) <request body> -- The accession to create

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## GET /repositories/:repo_id/accessions/:accession_id 

### Description

Get an Accession by ID

### Parameters

	Integer accession_id -- The accession ID

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- (:accession)

	
## POST /repositories/:repo_id/accessions/:accession_id 

### Description

Update an Accession

### Parameters

	Integer accession_id -- The accession ID to update

	JSONModel(:accession) <request body> -- The accession data to update

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## POST /repositories/:repo_id/archival_objects 

### Description

Create an Archival Object

### Parameters

	JSONModel(:archival_object) <request body> -- The Archival Object to create

	Integer repo_id -- The Repository ID

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {"error":{"[:resource_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}

	
## GET /repositories/:repo_id/archival_objects 

### Description

Get a list of Archival Objects for a Repository

### Parameters

	Integer repo_id -- The Repository ID

### Returns

	200 -- [(:archival_object)]

	
## POST /repositories/:repo_id/archival_objects/:archival_object_id 

### Description

Update an Archival Object

### Parameters

	Integer archival_object_id -- The Archival Object ID to update

	JSONModel(:archival_object) <request body> -- The Archival Object data to update

	Integer repo_id -- The Repository ID

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}
	409 -- {"error":{"[:resource_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}

	
## GET /repositories/:repo_id/archival_objects/:archival_object_id 

### Description

Get an Archival Object by ID

### Parameters

	Integer archival_object_id -- The Archival Object ID

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

### Returns

	200 -- (:archival_object)
	404 -- {"error":"ArchivalObject not found"}

	
## GET /repositories/:repo_id/archival_objects/:archival_object_id/children 

### Description

Get the children of an Archival Object

### Parameters

	Integer archival_object_id -- The Archival Object ID

	Integer repo_id -- The Repository ID

### Returns

	200 -- [(:archival_object)]
	404 -- {"error":"ArchivalObject not found"}

	
## POST /repositories/:repo_id/resources 

### Description

Create a Resource

### Parameters

	JSONModel(:resource) <request body> -- The resource to create

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## GET /repositories/:repo_id/resources 

### Description

Get a list of Resources for a Repository

### Parameters

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- [(:resource)]

	
## GET /repositories/:repo_id/resources/:resource_id 

### Description

Get a Resource

### Parameters

	Integer resource_id -- The ID of the resource to retrieve

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

### Returns

	200 -- (:resource)

	
## POST /repositories/:repo_id/resources/:resource_id 

### Description

Update a Resource

### Parameters

	Integer resource_id -- The ID of the resource to retrieve

	JSONModel(:resource) <request body> -- The resource to update

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## GET /repositories/:repo_id/resources/:resource_id/tree 

### Description

Get a Resource tree

### Parameters

	Integer resource_id -- The ID of the resource to retrieve

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- OK

	
## POST /repositories/:repo_id/resources/:resource_id/tree 

### Description

Update a Resource tree

### Parameters

	Integer resource_id -- The ID of the resource to retrieve

	JSONModel(:resource_tree) <request body> -- A JSON tree representing the modified hierarchy

	Integer repo_id -- The Repository ID -- The Repository must exist

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## POST /subjects 

### Description

Create a Subject

### Parameters

	JSONModel(:subject) <request body> -- The subject data to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## GET /subjects 

### Description

Get a list of Subjects

### Parameters

### Returns

	200 -- [(:subject)]

	
## GET /subjects/:subject_id 

### Description

Get a Subject by ID

### Parameters

	Integer subject_id -- The subject ID

### Returns

	200 -- (:subject)

	
## POST /users 

### Description

Create a local user

### Parameters

	String password -- The user's password

	JSONModel(:user) <request body> -- The user to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /users/:username/login 

### Description

Log in

### Parameters

	 username -- Your username

	 password -- Your password

### Returns

	200 -- Login accepted
	403 -- Login failed

	
## GET /vocabularies 

### Description

Get a list of Vocabularies

### Parameters

	String ref_id -- An alternate, externally-created ID for the vocabulary

### Returns

	200 -- [(:vocabulary)]

	
## POST /vocabularies 

### Description

Create a Vocabulary

### Parameters

	JSONModel(:vocabulary) <request body> -- The vocabulary data to create

### Returns

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## POST /vocabularies/:vocab_id 

### Description

Update a Vocabulary

### Parameters

	Integer vocab_id -- The vocabulary ID to update

	JSONModel(:vocabulary) <request body> -- The vocabulary data to update

### Returns

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## GET /vocabularies/:vocab_id 

### Description

Get a Vocabulary by ID

### Parameters

	Integer vocab_id -- The vocabulary ID

### Returns

	200 -- OK

	
## GET /vocabularies/:vocab_id/terms 

### Description

Get a list of Terms for a Vocabulary

### Parameters

	Integer vocab_id -- The vocabulary ID

### Returns

	200 -- [(:term)]



