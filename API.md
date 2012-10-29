# ArchivesSpace REST API
As of 2012-10-29 18:48:01 -0400 the following REST endpoints exist:

	
## GET /agents 

__Description__

Get all agent records

__Parameters__

__Returns__

	200 -- [(:agent)]

	
## GET /agents/by-name 

__Description__

Get all agent records by their sort name

__Parameters__

	(?-mix:[\w0-9 -.]) q -- The name prefix to match

__Returns__

	200 -- [(:agent)]

	
## POST /agents/corporate_entities 

__Description__

Create a corporate entity agent

__Parameters__

	JSONModel(:agent_corporate_entity) <request body> -- The corporate entity to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /agents/corporate_entities/:agent_id 

__Description__

Update a corporate entity agent

__Parameters__

	Integer agent_id -- The ID of the agent to update

	JSONModel(:agent_corporate_entity) <request body> -- The corporate entity to create

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /agents/corporate_entities/:id 

__Description__

Get a corporate entity by ID

__Parameters__

	Integer id -- ID of the corporate entity agent

__Returns__

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## POST /agents/families 

__Description__

Create a family agent

__Parameters__

	JSONModel(:agent_family) <request body> -- The family to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /agents/families/:agent_id 

__Description__

Update a family agent

__Parameters__

	Integer agent_id -- The ID of the agent to update

	JSONModel(:agent_family) <request body> -- The family to create

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /agents/families/:id 

__Description__

Get a family by ID

__Parameters__

	Integer id -- ID of the family agent

__Returns__

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## POST /agents/people 

__Description__

Create a person agent

__Parameters__

	JSONModel(:agent_person) <request body> -- The person to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /agents/people/:agent_id 

__Description__

Update a person agent

__Parameters__

	Integer agent_id -- The ID of the agent to update

	JSONModel(:agent_person) <request body> -- The person to create

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /agents/people/:id 

__Description__

Get a person by ID

__Parameters__

	Integer id -- ID of the person agent

__Returns__

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## POST /agents/software 

__Description__

Create a software agent

__Parameters__

	JSONModel(:agent_software) <request body> -- The software to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /agents/software/:agent_id 

__Description__

Update a software agent

__Parameters__

	Integer agent_id -- The ID of the software to update

	JSONModel(:agent_software) <request body> -- The software to create

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /agents/software/:id 

__Description__

Get a software by ID

__Parameters__

	Integer id -- ID of the software agent

__Returns__

	200 -- (:agent)
	404 -- {"error":"Agent not found"}

	
## GET /permissions 

__Description__

Get a list of Permissions

__Parameters__

	String level -- The permission level to get (one of: repository, global, all) -- Must be one of repository, global, all

__Returns__

	200 -- [(:permission)]

	
## POST /repositories 

__Description__

Create a Repository

__Parameters__

	JSONModel(:repository) <request body> -- The repository to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	403 -- access_denied

	
## GET /repositories 

__Description__

Get a list of Repositories

__Parameters__

__Returns__

	200 -- [(:repository)]

	
## GET /repositories/:id 

__Description__

Get a Repository by ID

__Parameters__

	Integer id -- ID of the repository

__Returns__

	200 -- (:repository)
	404 -- {"error":"Repository not found"}

	
## POST /repositories/:repo_id/accessions 

__Description__

Create an Accession

__Parameters__

	JSONModel(:accession) <request body> -- The accession to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## GET /repositories/:repo_id/accessions 

__Description__

Get a list of Accessions for a Repository

__Parameters__

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:accession)]

	
## GET /repositories/:repo_id/accessions/:accession_id 

__Description__

Get an Accession by ID

__Parameters__

	Integer accession_id -- The accession ID

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:accession)

	
## POST /repositories/:repo_id/accessions/:accession_id 

__Description__

Update an Accession

__Parameters__

	Integer accession_id -- The accession ID to update

	JSONModel(:accession) <request body> -- The accession data to update

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## GET /repositories/:repo_id/archival_objects 

__Description__

Get a list of Archival Objects for a Repository

__Parameters__

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:archival_object)]

	
## POST /repositories/:repo_id/archival_objects 

__Description__

Create an Archival Object

__Parameters__

	JSONModel(:archival_object) <request body> -- The Archival Object to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {"error":{"[:resource_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}

	
## POST /repositories/:repo_id/archival_objects/:archival_object_id 

__Description__

Update an Archival Object

__Parameters__

	Integer archival_object_id -- The Archival Object ID to update

	JSONModel(:archival_object) <request body> -- The Archival Object data to update

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}
	409 -- {"error":{"[:resource_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}

	
## GET /repositories/:repo_id/archival_objects/:archival_object_id 

__Description__

Get an Archival Object by ID

__Parameters__

	Integer archival_object_id -- The Archival Object ID

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:archival_object)
	404 -- {"error":"ArchivalObject not found"}

	
## GET /repositories/:repo_id/archival_objects/:archival_object_id/children 

__Description__

Get the children of an Archival Object

__Parameters__

	Integer archival_object_id -- The Archival Object ID

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:archival_object)]
	404 -- {"error":"ArchivalObject not found"}

	
## GET /repositories/:repo_id/digital_object_components 

__Description__

Get a list of Digital Object Components for a Repository

__Parameters__

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object_component)]

	
## POST /repositories/:repo_id/digital_object_components 

__Description__

Create an Digital Object Component

__Parameters__

	JSONModel(:digital_object_component) <request body> -- The Digital Object Component to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## POST /repositories/:repo_id/digital_object_components/:digital_object_component_id 

__Description__

Update an Digital Object Component

__Parameters__

	Integer digital_object_component_id -- The Digital Object Component ID to update

	JSONModel(:digital_object_component) <request body> -- The Digital Object Component data to update

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /repositories/:repo_id/digital_object_components/:digital_object_component_id 

__Description__

Get an Digital Object Component by ID

__Parameters__

	Integer digital_object_component_id -- The Digital Object Component ID

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:digital_object_component)
	404 -- {"error":"DigitalObjectComponent not found"}

	
## GET /repositories/:repo_id/digital_object_components/:digital_object_component_id/children 

__Description__

Get the children of an Digital Object Component

__Parameters__

	Integer digital_object_component_id -- The Digital Object Component ID

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object_component)]
	404 -- {"error":"DigitalObjectComponent not found"}

	
## GET /repositories/:repo_id/digital_objects 

__Description__

Get a list of Digital Objects for a Repository

__Parameters__

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object)]

	
## POST /repositories/:repo_id/digital_objects 

__Description__

Create a Digital Object

__Parameters__

	JSONModel(:digital_object) <request body> -- The digital object to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## GET /repositories/:repo_id/digital_objects/:digital_object_id 

__Description__

Get a Digital Object

__Parameters__

	Integer digital_object_id -- The ID of the digital object to retrieve

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:digital_object)

	
## POST /repositories/:repo_id/digital_objects/:digital_object_id 

__Description__

Update a Digital Object

__Parameters__

	Integer digital_object_id -- The ID of the digital object to retrieve

	JSONModel(:digital_object) <request body> -- The digital object to update

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /repositories/:repo_id/digital_objects/:digital_object_id/tree 

__Description__

Get a Digital Object tree

__Parameters__

	Integer digital_object_id -- The ID of the digital object to retrieve

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK

	
## POST /repositories/:repo_id/digital_objects/:digital_object_id/tree 

__Description__

Update a Digital Object tree

__Parameters__

	Integer digital_object_id -- The ID of the digital object to retrieve

	JSONModel(:digital_object_tree) <request body> -- A JSON tree representing the modified hierarchy

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## POST /repositories/:repo_id/events 

__Description__

Create an Event

__Parameters__

	JSONModel(:event) <request body> -- The Event to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## GET /repositories/:repo_id/events 

__Description__

Get a list of Events for a Repository

__Parameters__

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:event)]

	
## GET /repositories/:repo_id/events/:event_id 

__Description__

Get an Event by ID

__Parameters__

	Integer event_id -- The Event ID

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:event)
	404 -- {"error":"Event not found"}

	
## POST /repositories/:repo_id/events/:event_id 

__Description__

Update an Event

__Parameters__

	Integer event_id -- The event ID to update

	JSONModel(:event) <request body> -- The event data to update

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## GET /repositories/:repo_id/events/linkable-records/list 

__Description__

Get a list of records matching some search criteria that can be linked to an event

__Parameters__

	(?-mix:[\w0-9 -.]) q -- The record title prefix to match

__Returns__

	200 -- A list of matching records

	
## GET /repositories/:repo_id/groups 

__Description__

Get a list of groups for a repository

__Parameters__

	Integer repo_id -- The Repository ID -- The Repository must exist

	String group_code -- Get groups by group code

__Returns__

	200 -- [(:resource)]

	
## POST /repositories/:repo_id/groups 

__Description__

Create a group within a repository

__Parameters__

	JSONModel(:group) <request body> -- The group to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- conflict

	
## GET /repositories/:repo_id/groups/:group_id 

__Description__

Get a group by ID

__Parameters__

	Integer group_id -- The group ID

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam with_members -- If 'true' (the default) return the list of members with the group

__Returns__

	200 -- (:group)
	404 -- {"error":"Group not found"}

	
## POST /repositories/:repo_id/groups/:group_id 

__Description__

Update a group

__Parameters__

	Integer group_id -- The Group ID to update

	JSONModel(:group) <request body> -- The Group data to update

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam with_members -- If 'true' (the default) replace the membership list with the list provided

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}
	409 -- conflict

	
## GET /repositories/:repo_id/locations 

__Description__

Get a list of locations

__Parameters__

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:location)]

	
## POST /repositories/:repo_id/locations 

__Description__

Create a Location

__Parameters__

	JSONModel(:location) <request body> -- The location data to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## GET /repositories/:repo_id/locations/:location_id 

__Description__

Get a Location by ID

__Parameters__

	Integer location_id -- The Location ID

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:location)

	
## POST /repositories/:repo_id/locations/:location_id 

__Description__

Update a Location

__Parameters__

	Integer location_id -- The ID of the location to update

	JSONModel(:location) <request body> -- The location data to update

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## GET /repositories/:repo_id/resource_descriptions/:resource_id.xml 

__Description__

Get an EAD representation of a Resource 

__Parameters__

	Integer resource_id -- The ID of the resource to retrieve

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)

	
## POST /repositories/:repo_id/resources 

__Description__

Create a Resource

__Parameters__

	JSONModel(:resource) <request body> -- The resource to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## GET /repositories/:repo_id/resources 

__Description__

Get a list of Resources for a Repository

__Parameters__

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:resource)]

	
## GET /repositories/:repo_id/resources/:resource_id 

__Description__

Get a Resource

__Parameters__

	Integer resource_id -- The ID of the resource to retrieve

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:resource)

	
## POST /repositories/:repo_id/resources/:resource_id 

__Description__

Update a Resource

__Parameters__

	Integer resource_id -- The ID of the resource to retrieve

	JSONModel(:resource) <request body> -- The resource to update

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}

	
## GET /repositories/:repo_id/resources/:resource_id/tree 

__Description__

Get a Resource tree

__Parameters__

	Integer resource_id -- The ID of the resource to retrieve

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK

	
## POST /repositories/:repo_id/resources/:resource_id/tree 

__Description__

Update a Resource tree

__Parameters__

	Integer resource_id -- The ID of the resource to retrieve

	JSONModel(:resource_tree) <request body> -- A JSON tree representing the modified hierarchy

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## POST /subjects 

__Description__

Create a Subject

__Parameters__

	JSONModel(:subject) <request body> -- The subject data to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## GET /subjects 

__Description__

Get a list of Subjects

__Parameters__

__Returns__

	200 -- [(:subject)]

	
## GET /subjects/:subject_id 

__Description__

Get a Subject by ID

__Parameters__

	Integer subject_id -- The subject ID

__Returns__

	200 -- (:subject)

	
## POST /users 

__Description__

Create a local user

__Parameters__

	String password -- The user's password

	JSONModel(:user) <request body> -- The user to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}

	
## GET /users/:username 

__Description__

Get a user's details (including their current permissions)

__Parameters__

	 username -- The username of interest

__Returns__

	200 -- (:user)

	
## POST /users/:username/login 

__Description__

Log in

__Parameters__

	 username -- Your username

	 password -- Your password

__Returns__

	200 -- Login accepted
	403 -- Login failed

	
## POST /vocabularies 

__Description__

Create a Vocabulary

__Parameters__

	JSONModel(:vocabulary) <request body> -- The vocabulary data to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

	
## GET /vocabularies 

__Description__

Get a list of Vocabularies

__Parameters__

	String ref_id -- An alternate, externally-created ID for the vocabulary

__Returns__

	200 -- [(:vocabulary)]

	
## GET /vocabularies/:vocab_id 

__Description__

Get a Vocabulary by ID

__Parameters__

	Integer vocab_id -- The vocabulary ID

__Returns__

	200 -- OK

	
## POST /vocabularies/:vocab_id 

__Description__

Update a Vocabulary

__Parameters__

	Integer vocab_id -- The vocabulary ID to update

	JSONModel(:vocabulary) <request body> -- The vocabulary data to update

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}

	
## GET /vocabularies/:vocab_id/terms 

__Description__

Get a list of Terms for a Vocabulary

__Parameters__

	Integer vocab_id -- The vocabulary ID

__Returns__

	200 -- [(:term)]

	
## POST /webhooks/register 

__Description__

-- No description provided --

__Parameters__

	String url -- The URL to receive POST notifications

__Returns__

	200 -- OK

	
## GET /webhooks/test 

__Description__

-- No description provided --

__Parameters__

__Returns__

	200 -- OK



