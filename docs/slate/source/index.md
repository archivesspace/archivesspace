---
title: API Reference

language_tabs:
  - shell

toc_footers:
  - <a href='http://github.com/tripit/slate'>Documentation Powered by Slate</a>

includes:
  - errors

search: true
---

# Introduction

This is the documentation for the ArchivesSpace RESTful API. This documents the endpoints that are used by the backend server to edit records in the application.

This example API documentation page was created with [Slate](http://github.com/tripit/slate). 

# Authentication

> To authorize, use this code:

<!-- 
```ruby
require 'kittn'

api = Kittn::APIClient.authorize!('meowmeowmeow')
```

```python
import kittn

api = kittn.authorize('meowmeowmeow')
```
-->

> Example Request:

```shell
# With shell, you can just pass the correct header with each request
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
```

> Example Response:

```json
{
   "session":"9528190655b979f00817a5d38f9daf07d1686fed99a1d53dd2c9ff2d852a0c6e",
   "user":{
      "lock_version":6,
      "username":"admin",
      "name":"Administrator",
      "is_system_user":true,
      "create_time":"2015-05-08T13:10:06Z",
      "system_mtime":"2015-07-07T10:21:53Z",
      "user_mtime":"2015-07-07T10:21:53Z",
      "jsonmodel_type":"user",
      "groups":[

      ],
      "is_admin":true,
      "uri":"/users/1",
      "agent_record":{
         "ref":"/agents/people/1"
      },
      "permissions":{
         "/repositories/1":[
            "update_location_record",
            "delete_vocabulary_record",
            "update_subject_record",
            "delete_subject_record",
            "update_agent_record",
            "delete_agent_record",
            "update_vocabulary_record",
            "merge_subject_record",
            "merge_agent_record",
            "administer_system",
            "become_user",
            "cancel_importer_job",
            "create_repository",
            "delete_archival_record",
            "delete_classification_record",
            "delete_event_record",
            "delete_repository",
            "import_records",
            "index_system",
            "manage_agent_record",
            "manage_repository",
            "manage_subject_record",
            "manage_users",
            "manage_vocabulary_record",
            "mediate_edits",
            "merge_agents_and_subjects",
            "merge_archival_record",
            "suppress_archival_record",
            "system_config",
            "transfer_archival_record",
            "transfer_repository",
            "update_accession_record",
            "update_classification_record",
            "update_digital_object_record",
            "update_event_record",
            "update_resource_record",
            "view_all_records",
            "view_repository",
            "view_suppressed"
         ],
         "_archivesspace":[
            "administer_system",
            "become_user",
            "cancel_importer_job",
            "create_repository",
            "delete_archival_record",
            "delete_classification_record",
            "delete_event_record",
            "delete_repository",
            "import_records",
            "index_system",
            "manage_agent_record",
            "manage_repository",
            "manage_subject_record",
            "manage_users",
            "manage_vocabulary_record",
            "mediate_edits",
            "merge_agents_and_subjects",
            "merge_archival_record",
            "suppress_archival_record",
            "system_config",
            "transfer_archival_record",
            "transfer_repository",
            "update_accession_record",
            "update_classification_record",
            "update_digital_object_record",
            "update_event_record",
            "update_resource_record",
            "view_all_records",
            "view_repository",
            "view_suppressed",
            "update_location_record",
            "delete_vocabulary_record",
            "update_subject_record",
            "delete_subject_record",
            "update_agent_record",
            "delete_agent_record",
            "update_vocabulary_record",
            "merge_subject_record",
            "merge_agent_record"
         ]
      }
   }
}
```

> It's a good idea to save the "session" id, since this will be used for later requests. 


Most requests to the ArchivesSpace backend requires a user to be authenticated.
This can be done with a simple POST request to the /users/:user_name/login
endpoint, with :user_name and :password parameters being supplied.

The JSON that is returned will have a session key, which can be stored and used
for other requests. Sessions will expire after an hour, although you can change this in your config.rb file.

# ArchivesSpace REST API
As of 2015-07-07 19:58:59 +0200 the following REST endpoints exist in the master branch of the development repository:


## POST /agents/corporate_entities 

__Description__

Create a corporate entity agent

__Parameters__


	JSONModel(:agent_corporate_entity) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /agents/corporate_entities 

__Description__

List all corporate entity agents

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

__Returns__

	200 -- [(:agent_corporate_entity)]


## POST /agents/corporate_entities/:id 

__Description__

Update a corporate entity agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_corporate_entity) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /agents/corporate_entities/:id 

__Description__

Get a corporate entity by ID

__Parameters__


	Integer id -- ID of the corporate entity agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


## DELETE /agents/corporate_entities/:id 

__Description__

Delete a corporate entity agent

__Parameters__


	Integer id -- ID of the corporate entity agent

__Returns__

	200 -- deleted


## POST /agents/families 

__Description__

Create a family agent

__Parameters__


	JSONModel(:agent_family) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /agents/families 

__Description__

List all family agents

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

__Returns__

	200 -- [(:agent_family)]


## DELETE /agents/families/:id 

__Description__

Delete an agent family

__Parameters__


	Integer id -- ID of the family agent

__Returns__

	200 -- deleted


## GET /agents/families/:id 

__Description__

Get a family by ID

__Parameters__


	Integer id -- ID of the family agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


## POST /agents/families/:id 

__Description__

Update a family agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_family) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /agents/people 

__Description__

List all person agents

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

__Returns__

	200 -- [(:agent_person)]


## POST /agents/people 

__Description__

Create a person agent

__Parameters__


	JSONModel(:agent_person) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## POST /agents/people/:id 

__Description__

Update a person agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_person) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /agents/people/:id 

__Description__

Get a person by ID

__Parameters__


	Integer id -- ID of the person agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


## DELETE /agents/people/:id 

__Description__

Delete an agent person

__Parameters__


	Integer id -- ID of the person agent

__Returns__

	200 -- deleted


## POST /agents/software 

__Description__

Create a software agent

__Parameters__


	JSONModel(:agent_software) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /agents/software 

__Description__

List all software agents

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

__Returns__

	200 -- [(:agent_software)]


## POST /agents/software/:id 

__Description__

Update a software agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_software) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /agents/software/:id 

__Description__

Get a software agent by ID

__Parameters__


	Integer id -- ID of the software agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


## DELETE /agents/software/:id 

__Description__

Delete a software agent

__Parameters__


	Integer id -- ID of the software agent

__Returns__

	200 -- deleted


## POST /batch_delete 

__Description__

Carry out delete requests against a list of records

__Parameters__


	[String] record_uris -- A list of record uris

__Returns__

	200 -- deleted


## GET /by-external-id 

__Description__

List records by their external ID(s)

__Parameters__


	String eid -- An external ID to find

	[String] type -- The record type to search (useful if IDs may be shared between different types)

__Returns__

	303 -- A redirect to the URI named by the external ID (if there's only one)
	300 -- A JSON-formatted list of URIs if there were multiple matches
	404 -- No external ID matched


## POST /config/enumeration_values/:enum_val_id 

__Description__

Update an enumeration value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	JSONModel(:enumeration_value) <request body> -- The enumeration value to update

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /config/enumeration_values/:enum_val_id 

__Description__

Get an Enumeration Value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to retrieve

__Returns__

	200 -- (:enumeration_value)


## POST /config/enumeration_values/:enum_val_id/position 

__Description__

Update the position of an ennumeration value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	Integer position -- The target position in the value list

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## POST /config/enumeration_values/:enum_val_id/suppressed 

__Description__

Suppress this value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	RESTHelpers::BooleanParam suppressed -- Suppression state

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}
	400 -- {:error => (description of error)}


## POST /config/enumerations 

__Description__

Create an enumeration

__Parameters__


	JSONModel(:enumeration) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /config/enumerations 

__Description__

List all defined enumerations

__Parameters__


__Returns__

	200 -- [(:enumeration)]


## POST /config/enumerations/:enum_id 

__Description__

Update an enumeration

__Parameters__


	Integer enum_id -- The ID of the enumeration to update

	JSONModel(:enumeration) <request body> -- The enumeration to update

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /config/enumerations/:enum_id 

__Description__

Get an Enumeration

__Parameters__


	Integer enum_id -- The ID of the enumeration to retrieve

__Returns__

	200 -- (:enumeration)


## POST /config/enumerations/migration 

__Description__

Migrate all records from using one value to another

__Parameters__


	JSONModel(:enumeration_migration) <request body> -- The migration request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /current_global_preferences 

__Description__

Get the global Preferences records for the current user.

__Parameters__


__Returns__

	200 -- {(:preference)}


## GET /delete-feed 

__Description__

Get a stream of deleted records

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

__Returns__

	200 -- a list of URIs that were deleted


## POST /locations 

__Description__

Create a Location

__Parameters__


	JSONModel(:location) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


## GET /locations 

__Description__

Get a list of locations

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

__Returns__

	200 -- [(:location)]


## POST /locations/:id 

__Description__

Update a Location

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:location) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /locations/:id 

__Description__

Get a Location by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:location)


## DELETE /locations/:id 

__Description__

Delete a Location

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


## POST /locations/batch 

__Description__

Create a Batch of Locations

__Parameters__


	RESTHelpers::BooleanParam dry_run -- If true, don't create the locations, just list them

	JSONModel(:location_batch) <request body> -- The location batch data to generate all locations

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## POST /locations/batch_update 

__Description__

Update a Location

__Parameters__


	JSONModel(:location_batch_update) <request body> -- The location batch data to update all locations

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## POST /merge_requests/agent 

__Description__

Carry out a merge request against Agent records

__Parameters__


	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## POST /merge_requests/digital_object 

__Description__

Carry out a merge request against Digital_Object records

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## POST /merge_requests/resource 

__Description__

Carry out a merge request against Resource records

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## POST /merge_requests/subject 

__Description__

Carry out a merge request against Subject records

__Parameters__


	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /notifications 

__Description__

Get a stream of notifications

__Parameters__


	Integer last_sequence -- The last sequence number seen

__Returns__

	200 -- a list of notifications


## GET /permissions 

__Description__

Get a list of Permissions

__Parameters__


	String level -- The permission level to get (one of: repository, global, all) -- Must be one of repository, global, all

__Returns__

	200 -- [(:permission)]


## GET /reports 

__Description__

List all reports

__Parameters__


__Returns__

	200 -- report list in json


## GET /reports/static/* 

__Description__

Get a static asset for a report

__Parameters__


	String splat -- The requested asset

__Returns__

	200 -- the asset


## POST /repositories 

__Description__

Create a Repository

__Parameters__


	JSONModel(:repository) <request body> -- The record to create

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


## POST /repositories/:id 

__Description__

Update a repository

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:repository) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /repositories/:id 

__Description__

Get a Repository by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:repository)
	404 -- Not found


## DELETE /repositories/:repo_id 

__Description__

Delete a Repository

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## GET /repositories/:repo_id/accessions 

__Description__

Get a list of Accessions for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:accession)]


## POST /repositories/:repo_id/accessions 

__Description__

Create an Accession

__Parameters__


	JSONModel(:accession) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


## GET /repositories/:repo_id/accessions/:id 

__Description__

Get an Accession by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:accession)


## DELETE /repositories/:repo_id/accessions/:id 

__Description__

Delete an Accession

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## POST /repositories/:repo_id/accessions/:id 

__Description__

Update an Accession

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:accession) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## POST /repositories/:repo_id/accessions/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


## POST /repositories/:repo_id/accessions/:id/transfer 

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved


## GET /repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a corporate entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/archival_contexts/corporate_entities/:id.xml 

__Description__

Get an EAC-CPF representation of a Corporate Entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


## GET /repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/archival_contexts/families/:id.xml 

__Description__

Get an EAC-CPF representation of a Family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


## GET /repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a person

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/archival_contexts/people/:id.xml 

__Description__

Get an EAC-CPF representation of an Agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


## GET /repositories/:repo_id/archival_contexts/softwares/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a software

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/archival_contexts/softwares/:id.xml 

__Description__

Get an EAC-CPF representation of a Software agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


## GET /repositories/:repo_id/archival_objects 

__Description__

Get a list of Archival Objects for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:archival_object)]


## POST /repositories/:repo_id/archival_objects 

__Description__

Create an Archival Object

__Parameters__


	JSONModel(:archival_object) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## DELETE /repositories/:repo_id/archival_objects/:id 

__Description__

Delete an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## GET /repositories/:repo_id/archival_objects/:id 

__Description__

Get an Archival Object by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:archival_object)
	404 -- Not found


## POST /repositories/:repo_id/archival_objects/:id 

__Description__

Update an Archival Object

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:archival_object) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## POST /repositories/:repo_id/archival_objects/:id/accept_children 

__Description__

Move existing Archival Objects to become children of an Archival Object

__Parameters__


	[String] children -- The children to move to the Archival Object

	Integer id -- The ID of the Archival Object to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## POST /repositories/:repo_id/archival_objects/:id/children 

__Description__

Batch create several Archival Objects as children of an existing Archival Object

__Parameters__


	JSONModel(:archival_record_children) <request body> -- The children to add to the archival object

	Integer id -- The ID of the archival object to add children to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## GET /repositories/:repo_id/archival_objects/:id/children 

__Description__

Get the children of an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of archival object references
	404 -- Not found


## POST /repositories/:repo_id/archival_objects/:id/parent 

__Description__

Set the parent/position of an Archival Object in a tree

__Parameters__


	Integer id -- The ID of the record

	Integer parent -- The parent of this node in the tree

	Integer position -- The position of this node in the tree

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## POST /repositories/:repo_id/archival_objects/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


## POST /repositories/:repo_id/batch_imports 

__Description__

Import a batch of records

__Parameters__


	body_stream batch_import -- The batch of records

	Integer repo_id -- The Repository ID -- The Repository must exist

	String migration -- param to indicate we are using a migrator

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## GET /repositories/:repo_id/classification_terms 

__Description__

Get a list of Classification Terms for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:classification_term)]


## POST /repositories/:repo_id/classification_terms 

__Description__

Create a Classification Term

__Parameters__


	JSONModel(:classification_term) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## POST /repositories/:repo_id/classification_terms/:id 

__Description__

Update a Classification Term

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:classification_term) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## DELETE /repositories/:repo_id/classification_terms/:id 

__Description__

Delete a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## GET /repositories/:repo_id/classification_terms/:id 

__Description__

Get a Classification Term by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:classification_term)
	404 -- Not found


## POST /repositories/:repo_id/classification_terms/:id/accept_children 

__Description__

Move existing Classification Terms to become children of another Classification Term

__Parameters__


	[String] children -- The children to move to the Classification Term

	Integer id -- The ID of the Classification Term to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## GET /repositories/:repo_id/classification_terms/:id/children 

__Description__

Get the children of a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of classification term references
	404 -- Not found


## POST /repositories/:repo_id/classification_terms/:id/parent 

__Description__

Set the parent/position of a Classification Term in a tree

__Parameters__


	Integer id -- The ID of the record

	Integer parent -- The parent of this node in the tree

	Integer position -- The position of this node in the tree

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /repositories/:repo_id/classifications 

__Description__

Get a list of Classifications for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:classification)]


## POST /repositories/:repo_id/classifications 

__Description__

Create a Classification

__Parameters__


	JSONModel(:classification) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## POST /repositories/:repo_id/classifications/:id 

__Description__

Update a Classification

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:classification) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /repositories/:repo_id/classifications/:id 

__Description__

Get a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:classification)


## DELETE /repositories/:repo_id/classifications/:id 

__Description__

Delete a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## POST /repositories/:repo_id/classifications/:id/accept_children 

__Description__

Move existing Classification Terms to become children of a Classification

__Parameters__


	[String] children -- The children to move to the Classification

	Integer id -- The ID of the Classification to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## GET /repositories/:repo_id/classifications/:id/tree 

__Description__

Get a Classification tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


## POST /repositories/:repo_id/component_transfers 

__Description__

Transfer components from one resource to another

__Parameters__


	String target_resource -- The URI of the resource to transfer into

	String component -- The URI of the archival object to transfer

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## GET /repositories/:repo_id/current_preferences 

__Description__

Get the Preferences records for the current repository and user.

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {(:preference)}


## GET /repositories/:repo_id/default_values/:record_type 

__Description__

Get default values for a record type

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## POST /repositories/:repo_id/default_values/:record_type 

__Description__

Save defaults for a record type

__Parameters__


	JSONModel(:default_values) <request body> -- The default values set

	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /repositories/:repo_id/digital_object_components 

__Description__

Get a list of Digital Object Components for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object_component)]


## POST /repositories/:repo_id/digital_object_components 

__Description__

Create an Digital Object Component

__Parameters__


	JSONModel(:digital_object_component) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## POST /repositories/:repo_id/digital_object_components/:id 

__Description__

Update an Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:digital_object_component) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## DELETE /repositories/:repo_id/digital_object_components/:id 

__Description__

Delete a Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## GET /repositories/:repo_id/digital_object_components/:id 

__Description__

Get an Digital Object Component by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:digital_object_component)
	404 -- Not found


## POST /repositories/:repo_id/digital_object_components/:id/accept_children 

__Description__

Move existing Digital Object Components to become children of a Digital Object Component

__Parameters__


	[String] children -- The children to move to the Digital Object Component

	Integer id -- The ID of the Digital Object Component to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## POST /repositories/:repo_id/digital_object_components/:id/children 

__Description__

Batch create several Digital Object Components as children of an existing Digital Object Component

__Parameters__


	JSONModel(:digital_record_children) <request body> -- The children to add to the digital object component

	Integer id -- The ID of the digital object component to add children to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## GET /repositories/:repo_id/digital_object_components/:id/children 

__Description__

Get the children of an Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object_component)]
	404 -- Not found


## POST /repositories/:repo_id/digital_object_components/:id/parent 

__Description__

Set the parent/position of an Digital Object Component in a tree

__Parameters__


	Integer id -- The ID of the record

	Integer parent -- The parent of this node in the tree

	Integer position -- The position of this node in the tree

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## POST /repositories/:repo_id/digital_object_components/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


## GET /repositories/:repo_id/digital_objects 

__Description__

Get a list of Digital Objects for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object)]


## POST /repositories/:repo_id/digital_objects 

__Description__

Create a Digital Object

__Parameters__


	JSONModel(:digital_object) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /repositories/:repo_id/digital_objects/:id 

__Description__

Get a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:digital_object)


## POST /repositories/:repo_id/digital_objects/:id 

__Description__

Update a Digital Object

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:digital_object) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## DELETE /repositories/:repo_id/digital_objects/:id 

__Description__

Delete a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## POST /repositories/:repo_id/digital_objects/:id/accept_children 

__Description__

Move existing Digital Object components to become children of a Digital Object

__Parameters__


	[String] children -- The children to move to the Digital Object

	Integer id -- The ID of the Digital Object to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## POST /repositories/:repo_id/digital_objects/:id/children 

__Description__

Batch create several Digital Object Components as children of an existing Digital Object

__Parameters__


	JSONModel(:digital_record_children) <request body> -- The component children to add to the digital object

	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## POST /repositories/:repo_id/digital_objects/:id/publish 

__Description__

Publish a digital object and all its sub-records and components

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## POST /repositories/:repo_id/digital_objects/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


## POST /repositories/:repo_id/digital_objects/:id/transfer 

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved


## GET /repositories/:repo_id/digital_objects/:id/tree 

__Description__

Get a Digital Object tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


## GET /repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata 

__Description__

Get metadata for a Dublin Core export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/digital_objects/dublin_core/:id.xml 

__Description__

Get a Dublin Core representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)


## GET /repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata 

__Description__

Get metadata for a METS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/digital_objects/mets/:id.xml 

__Description__

Get a METS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)


## GET /repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata 

__Description__

Get metadata for a MODS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/digital_objects/mods/:id.xml 

__Description__

Get a MODS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)


## POST /repositories/:repo_id/events 

__Description__

Create an Event

__Parameters__


	JSONModel(:event) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /repositories/:repo_id/events 

__Description__

Get a list of Events for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:event)]


## POST /repositories/:repo_id/events/:id 

__Description__

Update an Event

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:event) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /repositories/:repo_id/events/:id 

__Description__

Get an Event by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:event)
	404 -- Not found


## DELETE /repositories/:repo_id/events/:id 

__Description__

Delete an event record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## POST /repositories/:repo_id/events/:id/suppressed 

__Description__

Suppress this record from non-managers

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


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


	JSONModel(:group) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- conflict


## DELETE /repositories/:repo_id/groups/:id 

__Description__

Delete a group by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:group)
	404 -- Not found


## GET /repositories/:repo_id/groups/:id 

__Description__

Get a group by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam with_members -- If 'true' (the default) return the list of members with the group

__Returns__

	200 -- (:group)
	404 -- Not found


## POST /repositories/:repo_id/groups/:id 

__Description__

Update a group

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:group) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam with_members -- If 'true' (the default) replace the membership list with the list provided

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}
	409 -- conflict


## POST /repositories/:repo_id/jobs 

__Description__

Create a new import job

__Parameters__


	JSONModel(:job) <request body> -- The job object

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /repositories/:repo_id/jobs 

__Description__

Get a list of Jobs for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:job)]


## GET /repositories/:repo_id/jobs/:id 

__Description__

Get a Job by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:job)


## POST /repositories/:repo_id/jobs/:id/cancel 

__Description__

Cancel a job

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /repositories/:repo_id/jobs/:id/log 

__Description__

Get a Job's log by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::NonNegativeInteger offset -- The byte offset of the log file to show

__Returns__

	200 -- The section of the import log between 'offset' and the end of file


## GET /repositories/:repo_id/jobs/:id/output_files 

__Description__

Get a list of Job's output files by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- An array of output files


## GET /repositories/:repo_id/jobs/:id/output_files/:file_id 

__Description__

Get a Job's output file by ID

__Parameters__


	Integer id -- The ID of the record

	Integer file_id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- Returns the file


## GET /repositories/:repo_id/jobs/:id/records 

__Description__

Get a Job's list of created URIs

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- An array of created records


## GET /repositories/:repo_id/jobs/active 

__Description__

Get a list of all active Jobs for a Repository

__Parameters__


	[String] resolve -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:job)]


## GET /repositories/:repo_id/jobs/archived 

__Description__

Get a list of all archived Jobs for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	[String] resolve -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:job)]


## GET /repositories/:repo_id/jobs/import_types 

__Description__

List all supported import job types

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- A list of supported import types


## GET /repositories/:repo_id/jobs/types 

__Description__

List all supported import job types

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- A list of supported job types


## POST /repositories/:repo_id/jobs_with_files 

__Description__

Create a new import job and post input files

__Parameters__


	JSONModel(:job) job -- 

	[RESTHelpers::UploadFile] files -- 

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /repositories/:repo_id/preferences 

__Description__

Get a list of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer user_id -- The username to retrieve defaults for

__Returns__

	200 -- [(:preference)]


## POST /repositories/:repo_id/preferences 

__Description__

Create a Preferences record

__Parameters__


	JSONModel(:preference) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## DELETE /repositories/:repo_id/preferences/:id 

__Description__

Delete a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## POST /repositories/:repo_id/preferences/:id 

__Description__

Update a Preferences record

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:preference) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## GET /repositories/:repo_id/preferences/:id 

__Description__

Get a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:preference)


## GET /repositories/:repo_id/preferences/defaults 

__Description__

Get the default set of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String username -- The username to retrieve defaults for

__Returns__

	200 -- (defaults)


## POST /repositories/:repo_id/rde_templates 

__Description__

Create an RDE template

__Parameters__


	JSONModel(:rde_template) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /repositories/:repo_id/rde_templates 

__Description__

Get a list of RDE Templates

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:rde_template)]


## GET /repositories/:repo_id/rde_templates/:id 

__Description__

Get an RDE template record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:rde_template)


## DELETE /repositories/:repo_id/rde_templates/:id 

__Description__

Delete an RDE Template

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## GET /repositories/:repo_id/resource_descriptions/:id.:fmt/metadata 

__Description__

Get export metadata for a Resource Description

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	String fmt -- Format of the request

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/resource_descriptions/:id.pdf 

__Description__

Get an EAD representation of a Resource

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam include_unpublished -- Include unpublished records

	RESTHelpers::BooleanParam include_daos -- Include digital objects in dao tags

	RESTHelpers::BooleanParam numbered_cs -- Use numbered <c> tags in ead

	RESTHelpers::BooleanParam print_pdf -- Print EAD to pdf

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)


## GET /repositories/:repo_id/resource_descriptions/:id.xml 

__Description__

Get an EAD representation of a Resource

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam include_unpublished -- Include unpublished records

	RESTHelpers::BooleanParam include_daos -- Include digital objects in dao tags

	RESTHelpers::BooleanParam numbered_cs -- Use numbered <c> tags in ead

	RESTHelpers::BooleanParam print_pdf -- Print EAD to pdf

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)


## GET /repositories/:repo_id/resource_labels/:id.:fmt/metadata 

__Description__

Get export metadata for Resource labels

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/resource_labels/:id.tsv 

__Description__

Get a tsv list of printable labels for a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)


## POST /repositories/:repo_id/resources 

__Description__

Create a Resource

__Parameters__


	JSONModel(:resource) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /repositories/:repo_id/resources 

__Description__

Get a list of Resources for a Repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:resource)]


## GET /repositories/:repo_id/resources/:id 

__Description__

Get a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:resource)


## POST /repositories/:repo_id/resources/:id 

__Description__

Update a Resource

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:resource) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## DELETE /repositories/:repo_id/resources/:id 

__Description__

Delete a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


## POST /repositories/:repo_id/resources/:id/accept_children 

__Description__

Move existing Archival Objects to become children of a Resource

__Parameters__


	[String] children -- The children to move to the Resource

	Integer id -- The ID of the Resource to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## POST /repositories/:repo_id/resources/:id/children 

__Description__

Batch create several Archival Objects as children of an existing Resource

__Parameters__


	JSONModel(:archival_record_children) <request body> -- The children to add to the resource

	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


## GET /repositories/:repo_id/resources/:id/models_in_graph 

__Description__

Get a list of record types in the graph of a resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


## POST /repositories/:repo_id/resources/:id/publish 

__Description__

Publish a resource and all its sub-records and components

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## POST /repositories/:repo_id/resources/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


## POST /repositories/:repo_id/resources/:id/transfer 

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved


## GET /repositories/:repo_id/resources/:id/tree 

__Description__

Get a Resource tree

__Parameters__


	Integer id -- The ID of the record

	String limit_to -- An Archival Object URI or 'root'

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


## GET /repositories/:repo_id/resources/marc21/:id.:fmt/metadata 

__Description__

Get metadata for a MARC21 export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


## GET /repositories/:repo_id/resources/marc21/:id.xml 

__Description__

Get a MARC 21 representation of a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)


## GET /repositories/:repo_id/search 

__Description__

Search this repository

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	Integer repo_id -- The Repository ID -- The Repository must exist

	String q -- A search query string

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

__Returns__

	200 -- 


## POST /repositories/:repo_id/transfer 

__Description__

Transfer this record to a different repository

__Parameters__


	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved


## GET /repositories/:repo_id/users/:id 

__Description__

Get a user's details including their groups for the current repository

__Parameters__


	Integer id -- The username id to fetch

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:user)


## POST /repositories/with_agent 

__Description__

Create a Repository with an agent representation

__Parameters__


	JSONModel(:repository_with_agent) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	403 -- access_denied


## POST /repositories/with_agent/:id 

__Description__

Update a repository with an agent representation

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:repository_with_agent) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /repositories/with_agent/:id 

__Description__

Get a Repository by ID, including its agent representation

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:repository_with_agent)
	404 -- Not found


## GET /search 

__Description__

Search this archive

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	String q -- A search query string

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

__Returns__

	200 -- 


## GET /search/published_tree 

__Description__

Find the tree view for a particular archival record

__Parameters__


	String node_uri -- The URI of the archival record to find the tree view for

__Returns__

	200 -- OK
	404 -- Not found


## GET /search/repositories 

__Description__

Search across repositories

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	String q -- A search query string

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

__Returns__

	200 -- 


## GET /search/subjects 

__Description__

Search across subjects

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

	String q -- A search query string

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

__Returns__

	200 -- 


## POST /subjects 

__Description__

Create a Subject

__Parameters__


	JSONModel(:subject) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


## GET /subjects 

__Description__

Get a list of Subjects

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

__Returns__

	200 -- [(:subject)]


## DELETE /subjects/:id 

__Description__

Delete a Subject

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


## GET /subjects/:id 

__Description__

Get a Subject by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:subject)


## POST /subjects/:id 

__Description__

Update a Subject

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:subject) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /terms 

__Description__

Get a list of Terms matching a prefix

__Parameters__


	String q -- The prefix to match

__Returns__

	200 -- [(:term)]


## GET /update-feed 

__Description__

Get a stream of updated records

__Parameters__


	Integer last_sequence -- The last sequence number seen

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- a list of records and sequence numbers


## POST /update_monitor 

__Description__

Refresh the list of currently known edits

__Parameters__


	JSONModel(:active_edits) <request body> -- The list of active edits

__Returns__

	200 -- A list of records, the user editing it and the lock version for each


## POST /users 

__Description__

Create a local user

__Parameters__


	String password -- The user's password

	[String] groups -- Array of groups URIs to assign the user to

	JSONModel(:user) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


## GET /users 

__Description__

Get a list of users

__Parameters__

<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma seperated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>  
</aside>

__Returns__

	200 -- [(:resource)]


## DELETE /users/:id 

__Description__

Delete a user

__Parameters__


	Integer id -- The user to delete

__Returns__

	200 -- deleted


## GET /users/:id 

__Description__

Get a user's details (including their current permissions)

__Parameters__


	Integer id -- The username id to fetch

__Returns__

	200 -- (:user)


## POST /users/:id 

__Description__

Update a user's account

__Parameters__


	Integer id -- The ID of the record

	String password -- The user's password

	[String] groups -- Array of groups URIs to assign the user to

	RESTHelpers::BooleanParam remove_groups -- Remove all groups from the user for the current repo_id if true

	Integer repo_id -- The Repository groups to clear

	JSONModel(:user) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


## POST /users/:username/become-user 

__Description__

Become a different user

__Parameters__


	Username username -- The username to become

__Returns__

	200 -- Accepted
	404 -- User not found


## POST /users/:username/login 

__Description__

Log in

__Parameters__


	Username username -- Your username

	String password -- Your password

	RESTHelpers::BooleanParam expiring -- true if the created session should expire

__Returns__

	200 -- Login accepted
	403 -- Login failed


## GET /users/complete 

__Description__

Get a list of system users

__Parameters__


	String query -- A prefix to search for

__Returns__

	200 -- A list of usernames


## GET /users/current-user 

__Description__

Get the currently logged in user

__Parameters__


__Returns__

	200 -- (:user)
	404 -- Not logged in


## GET /version 

__Description__

Get the ArchivesSpace application version

__Parameters__


__Returns__

	200 -- ArchivesSpace (version)


## POST /vocabularies 

__Description__

Create a Vocabulary

__Parameters__


	JSONModel(:vocabulary) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


## GET /vocabularies 

__Description__

Get a list of Vocabularies

__Parameters__


	String ref_id -- An alternate, externally-created ID for the vocabulary

__Returns__

	200 -- [(:vocabulary)]


## POST /vocabularies/:id 

__Description__

Update a Vocabulary

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:vocabulary) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


## GET /vocabularies/:id 

__Description__

Get a Vocabulary by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- OK


## GET /vocabularies/:id/terms 

__Description__

Get a list of Terms for a Vocabulary

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- [(:term)]



