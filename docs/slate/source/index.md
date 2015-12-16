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

> Example Request:

```shell
# With shell, you can just pass the correct header with each request
$ curl -s -F password="admin" "http://localhost:8089/users/admin/login"
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

```shell
$ export SESSION=9528190655b979f00817a5d38f9daf07d1686fed99a1d53dd2c9ff2d852a0c6e
```

> We'll use the $SESSION variable in the following examples. 

Most requests to the ArchivesSpace backend requires a user to be authenticated.
This can be done with a simple POST request to the /users/:user_name/login
endpoint, with :user_name and :password parameters being supplied.

The JSON that is returned will have a session key, which can be stored and used
for other requests. Sessions will expire after an hour, although you can change this in your config.rb file.

# ArchivesSpace REST API
As of 2015-12-16 18:57:41 +0100 the following REST endpoints exist in the master branch of the development repository:


## GET /agents/corporate_entities 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/agents/corporate_entities?page=1'
```

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




## POST /agents/corporate_entities 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "agent_corporate_entity",
  "agent_contacts": [
    {
      "jsonmodel_type": "agent_contact",
      "telephones": [
        {
          "jsonmodel_type": "telephone",
          "number_type": "cell",
          "number": "753 25202 1654 07054",
          "ext": "MHDPA"
        }
      ],
      "name": "Name Number 5",
      "address_1": "4H735534V",
      "country": "82691V643281",
      "fax": "440YPQR",
      "email": "HQ854RL",
      "email_signature": "PHCDG"
    }
  ],
  "linked_agent_roles": [

  ],
  "external_documents": [

  ],
  "rights_statements": [

  ],
  "notes": [

  ],
  "dates_of_existence": [
    {
      "jsonmodel_type": "date",
      "date_type": "bulk",
      "label": "existence",
      "begin": "1975-05-13",
      "end": "1975-05-13",
      "expression": "225E934M425"
    }
  ],
  "names": [
    {
      "jsonmodel_type": "name_corporate_entity",
      "use_dates": [

      ],
      "authorized": false,
      "is_display_name": false,
      "sort_name_auto_generate": true,
      "rules": "aacr",
      "primary_name": "Name Number 4",
      "subordinate_name_1": "Y730V810985",
      "subordinate_name_2": "VM55669861",
      "number": "843379REF",
      "sort_name": "SORT e - 2",
      "dates": "H950POS",
      "qualifier": "MSAY348"
    }
  ],
  "related_agents": [

  ],
  "agent_type": "agent_corporate_entity"
}  
 'http://localhost:8089/agents/corporate_entities'
```

__Description__

Create a corporate entity agent

__Parameters__


  <a href="#agent_corporate_entity">JSONModel(:agent_corporate_entity) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## DELETE /agents/corporate_entities/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/agents/corporate_entities/1'
```

__Description__

Delete a corporate entity agent

__Parameters__


	Integer id -- ID of the corporate entity agent

__Returns__

	200 -- deleted




## GET /agents/corporate_entities/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/agents/corporate_entities/1'
```

__Description__

Get a corporate entity by ID

__Parameters__


	Integer id -- ID of the corporate entity agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent_corporate_entity)
	404 -- Not found




## POST /agents/corporate_entities/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "agent_corporate_entity",
  "agent_contacts": [
    {
      "jsonmodel_type": "agent_contact",
      "telephones": [
        {
          "jsonmodel_type": "telephone",
          "number_type": "cell",
          "number": "753 25202 1654 07054",
          "ext": "MHDPA"
        }
      ],
      "name": "Name Number 5",
      "address_1": "4H735534V",
      "country": "82691V643281",
      "fax": "440YPQR",
      "email": "HQ854RL",
      "email_signature": "PHCDG"
    }
  ],
  "linked_agent_roles": [

  ],
  "external_documents": [

  ],
  "rights_statements": [

  ],
  "notes": [

  ],
  "dates_of_existence": [
    {
      "jsonmodel_type": "date",
      "date_type": "bulk",
      "label": "existence",
      "begin": "1975-05-13",
      "end": "1975-05-13",
      "expression": "225E934M425"
    }
  ],
  "names": [
    {
      "jsonmodel_type": "name_corporate_entity",
      "use_dates": [

      ],
      "authorized": false,
      "is_display_name": false,
      "sort_name_auto_generate": true,
      "rules": "aacr",
      "primary_name": "Name Number 4",
      "subordinate_name_1": "Y730V810985",
      "subordinate_name_2": "VM55669861",
      "number": "843379REF",
      "sort_name": "SORT e - 2",
      "dates": "H950POS",
      "qualifier": "MSAY348"
    }
  ],
  "related_agents": [

  ],
  "agent_type": "agent_corporate_entity"
}  
 'http://localhost:8089/agents/corporate_entities/1'
```

__Description__

Update a corporate entity agent

__Parameters__


	Integer id -- The ID of the record

  <a href="#agent_corporate_entity">JSONModel(:agent_corporate_entity) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## POST /agents/families 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/agents/families'
```

__Description__

Create a family agent

__Parameters__


  <a href="#agent_family">JSONModel(:agent_family) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /agents/families 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/agents/families?page=1'
```

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




## POST /agents/families/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/agents/families/1'
```

__Description__

Update a family agent

__Parameters__


	Integer id -- The ID of the record

  <a href="#agent_family">JSONModel(:agent_family) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## GET /agents/families/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/agents/families/1'
```

__Description__

Get a family by ID

__Parameters__


	Integer id -- ID of the family agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found




## DELETE /agents/families/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/agents/families/1'
```

__Description__

Delete an agent family

__Parameters__


	Integer id -- ID of the family agent

__Returns__

	200 -- deleted




## POST /agents/people 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/agents/people'
```

__Description__

Create a person agent

__Parameters__


  <a href="#agent_person">JSONModel(:agent_person) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /agents/people 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/agents/people?page=1'
```

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




## POST /agents/people/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/agents/people/1'
```

__Description__

Update a person agent

__Parameters__


	Integer id -- The ID of the record

  <a href="#agent_person">JSONModel(:agent_person) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## GET /agents/people/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/agents/people/1'
```

__Description__

Get a person by ID

__Parameters__


	Integer id -- ID of the person agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found




## DELETE /agents/people/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/agents/people/1'
```

__Description__

Delete an agent person

__Parameters__


	Integer id -- ID of the person agent

__Returns__

	200 -- deleted




## POST /agents/software 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "agent_software",
  "agent_contacts": [

  ],
  "linked_agent_roles": [

  ],
  "external_documents": [

  ],
  "rights_statements": [

  ],
  "notes": [

  ],
  "dates_of_existence": [
    {
      "jsonmodel_type": "date",
      "date_type": "bulk",
      "label": "existence",
      "begin": "1980-07-15",
      "end": "1980-07-15",
      "expression": "O235WL818"
    }
  ],
  "names": [
    {
      "jsonmodel_type": "name_software",
      "use_dates": [

      ],
      "authorized": false,
      "is_display_name": false,
      "sort_name_auto_generate": true,
      "rules": "aacr",
      "software_name": "Name Number 8",
      "sort_name": "SORT e - 5"
    }
  ],
  "agent_type": "agent_software"
}  
 'http://localhost:8089/agents/software'
```

__Description__

Create a software agent

__Parameters__


  <a href="#agent_software">JSONModel(:agent_software) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /agents/software 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/agents/software?page=1'
```

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




## DELETE /agents/software/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/agents/software/1'
```

__Description__

Delete a software agent

__Parameters__


	Integer id -- ID of the software agent

__Returns__

	200 -- deleted




## POST /agents/software/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/agents/software/1'
```

__Description__

Update a software agent

__Parameters__


	Integer id -- The ID of the record

  <a href="#agent_software">JSONModel(:agent_software) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## GET /agents/software/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/agents/software/1'
```

__Description__

Get a software agent by ID

__Parameters__


	Integer id -- ID of the software agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found




## POST /batch_delete 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 630JAUW  
 'http://localhost:8089/batch_delete'
```

__Description__

Carry out delete requests against a list of records

__Parameters__


	[String] record_uris -- A list of record uris

__Returns__

	200 -- deleted




## GET /by-external-id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/by-external-id'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "enumeration_value",
  "value": "627MSSA"
}  
 'http://localhost:8089/config/enumeration_values/:enum_val_id'
```

__Description__

Update an enumeration value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

  <a href="#enumeration_value">JSONModel(:enumeration_value) <request body> -- The enumeration value to update</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## GET /config/enumeration_values/:enum_val_id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/config/enumeration_values/:enum_val_id'
```

__Description__

Get an Enumeration Value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to retrieve

__Returns__

	200 -- (:enumeration_value)




## POST /config/enumeration_values/:enum_val_id/position 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/config/enumeration_values/:enum_val_id/position'
```

__Description__

Update the position of an ennumeration value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	Integer position -- The target position in the value list

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## POST /config/enumeration_values/:enum_val_id/suppressed 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d BooleanParam  
 'http://localhost:8089/config/enumeration_values/:enum_val_id/suppressed'
```

__Description__

Suppress this value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	RESTHelpers::BooleanParam suppressed -- Suppression state

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}
	400 -- {:error => (description of error)}




## POST /config/enumerations 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/config/enumerations'
```

__Description__

Create an enumeration

__Parameters__


  <a href="#enumeration">JSONModel(:enumeration) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /config/enumerations 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/config/enumerations'
```

__Description__

List all defined enumerations

__Parameters__


__Returns__

	200 -- [(:enumeration)]




## POST /config/enumerations/:enum_id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/config/enumerations/:enum_id'
```

__Description__

Update an enumeration

__Parameters__


	Integer enum_id -- The ID of the enumeration to update

  <a href="#enumeration">JSONModel(:enumeration) <request body> -- The enumeration to update</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## GET /config/enumerations/:enum_id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/config/enumerations/:enum_id'
```

__Description__

Get an Enumeration

__Parameters__


	Integer enum_id -- The ID of the enumeration to retrieve

__Returns__

	200 -- (:enumeration)




## POST /config/enumerations/migration 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "enumeration_migration",
  "enum_uri": "/config/enumerations/67",
  "from": "QJ738G248",
  "to": "AY99075036"
}  
 'http://localhost:8089/config/enumerations/migration'
```

__Description__

Migrate all records from using one value to another

__Parameters__


  <a href="#enumeration_migration">JSONModel(:enumeration_migration) <request body> -- The migration request</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## POST /container_profiles 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/container_profiles'
```

__Description__

Create a Container_Profile

__Parameters__


  <a href="#container_profile">JSONModel(:container_profile) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}




## GET /container_profiles 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/container_profiles?page=1'
```

__Description__

Get a list of Container Profiles

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

	200 -- [(:container_profile)]




## POST /container_profiles/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "container_profile",
  "name": "878EL926B",
  "url": "JJ392IV",
  "dimension_units": "inches",
  "extent_dimension": "width",
  "depth": "17",
  "height": "67",
  "width": "34"
}  
 'http://localhost:8089/container_profiles/1'
```

__Description__

Update a Container Profile

__Parameters__


	Integer id -- The ID of the record

  <a href="#container_profile">JSONModel(:container_profile) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /container_profiles/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/container_profiles/1'
```

__Description__

Get a Container Profile by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:container_profile)




## DELETE /container_profiles/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/container_profiles/1'
```

__Description__

Delete an Container Profile

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted




## GET /current_global_preferences 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/current_global_preferences'
```

__Description__

Get the global Preferences records for the current user.

__Parameters__


__Returns__

	200 -- {(:preference)}




## GET /delete-feed 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/delete-feed?page=1'
```

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




## GET /extent_calculator 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/extent_calculator'
```

__Description__

Calculate the extent of an archival object tree

__Parameters__


	String record_uri -- The uri of the object

	String unit -- The unit of measurement to use

__Returns__

	200 -- Calculation results




## POST /locations 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/locations'
```

__Description__

Create a Location

__Parameters__


  <a href="#location">JSONModel(:location) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}




## GET /locations 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/locations?page=1'
```

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




## DELETE /locations/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/locations/1'
```

__Description__

Delete a Location

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted




## GET /locations/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/locations/1'
```

__Description__

Get a Location by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:location)




## POST /locations/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "location",
  "external_ids": [

  ],
  "building": "32 E 9th Street",
  "floor": "11",
  "room": "3",
  "area": "Back",
  "barcode": "01101011000101100110",
  "temporary": "conservation"
}  
 'http://localhost:8089/locations/1'
```

__Description__

Update a Location

__Parameters__


	Integer id -- The ID of the record

  <a href="#location">JSONModel(:location) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /locations/batch 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "location_batch",
  "external_ids": [

  ],
  "locations": [

  ],
  "building": "41 W 7th Street",
  "floor": "11",
  "room": "5",
  "area": "Back",
  "barcode": "00101111001110011111",
  "temporary": "loan",
  "coordinate_1_range": {
    "label": "GUK746L",
    "start": "0",
    "end": "10"
  }
}  
 'http://localhost:8089/locations/batch'
```

__Description__

Create a Batch of Locations

__Parameters__


	RESTHelpers::BooleanParam dry_run -- If true, don't create the locations, just list them

  <a href="#location_batch">JSONModel(:location_batch) <request body> -- The location batch data to generate all locations</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /locations/batch_update 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "location_batch_update",
  "external_ids": [

  ],
  "record_uris": [

  ],
  "building": "114 E 6th Street",
  "floor": "6",
  "room": "3",
  "area": "Front",
  "barcode": "11001111001110011000",
  "temporary": "conservation"
}  
 'http://localhost:8089/locations/batch_update'
```

__Description__

Update a Location

__Parameters__


  <a href="#location_batch_update">JSONModel(:location_batch_update) <request body> -- The location batch data to update all locations</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /logout 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {}  
 'http://localhost:8089/logout'
```

__Description__

Log out the current session

__Parameters__


__Returns__

	200 -- Session logged out




## POST /merge_requests/agent 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "merge_request",
  "victims": [
    {
      "ref": "/repositories/2/resources/2"
    }
  ],
  "target": {
    "ref": "/repositories/2/resources/1"
  }
}  
 'http://localhost:8089/merge_requests/agent'
```

__Description__

Carry out a merge request against Agent records

__Parameters__


  <a href="#merge_request">JSONModel(:merge_request) <request body> -- A merge request</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /merge_requests/digital_object 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "merge_request",
  "victims": [
    {
      "ref": "/repositories/2/resources/2"
    }
  ],
  "target": {
    "ref": "/repositories/2/resources/1"
  }
}  
 'http://localhost:8089/merge_requests/digital_object'
```

__Description__

Carry out a merge request against Digital_Object records

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

  <a href="#merge_request">JSONModel(:merge_request) <request body> -- A merge request</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /merge_requests/resource 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "merge_request",
  "victims": [
    {
      "ref": "/repositories/2/resources/2"
    }
  ],
  "target": {
    "ref": "/repositories/2/resources/1"
  }
}  
 'http://localhost:8089/merge_requests/resource'
```

__Description__

Carry out a merge request against Resource records

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

  <a href="#merge_request">JSONModel(:merge_request) <request body> -- A merge request</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /merge_requests/subject 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "merge_request",
  "victims": [
    {
      "ref": "/repositories/2/resources/2"
    }
  ],
  "target": {
    "ref": "/repositories/2/resources/1"
  }
}  
 'http://localhost:8089/merge_requests/subject'
```

__Description__

Carry out a merge request against Subject records

__Parameters__


  <a href="#merge_request">JSONModel(:merge_request) <request body> -- A merge request</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /notifications 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/notifications'
```

__Description__

Get a stream of notifications

__Parameters__


	Integer last_sequence -- The last sequence number seen

__Returns__

	200 -- a list of notifications




## GET /permissions 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/permissions'
```

__Description__

Get a list of Permissions

__Parameters__


	String level -- The permission level to get (one of: repository, global, all) -- Must be one of repository, global, all

__Returns__

	200 -- [(:permission)]




## GET /reports 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/reports'
```

__Description__

List all reports

__Parameters__


__Returns__

	200 -- report list in json




## GET /reports/static/* 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/reports/static/*'
```

__Description__

Get a static asset for a report

__Parameters__


	String splat -- The requested asset

__Returns__

	200 -- the asset




## GET /repositories 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories'
```

__Description__

Get a list of Repositories

__Parameters__


__Returns__

	200 -- [(:repository)]




## POST /repositories 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "repository",
  "name": "Description: 11",
  "repo_code": "ASPACE REPO 2 -- 631024",
  "org_code": "970UV228G",
  "image_url": "http://www.example-3.com",
  "url": "http://www.example-4.com"
}  
 'http://localhost:8089/repositories'
```

__Description__

Create a Repository

__Parameters__


  <a href="#repository">JSONModel(:repository) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	403 -- access_denied




## POST /repositories/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "repository",
  "name": "Description: 11",
  "repo_code": "ASPACE REPO 2 -- 631024",
  "org_code": "970UV228G",
  "image_url": "http://www.example-3.com",
  "url": "http://www.example-4.com"
}  
 'http://localhost:8089/repositories/1'
```

__Description__

Update a repository

__Parameters__


	Integer id -- The ID of the record

  <a href="#repository">JSONModel(:repository) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /repositories/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/1'
```

__Description__

Get a Repository by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:repository)
	404 -- Not found




## DELETE /repositories/:repo_id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id'
```

__Description__

Delete a Repository

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## GET /repositories/:repo_id/accessions 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/accessions?page=1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/accessions'
```

__Description__

Create an Accession

__Parameters__


  <a href="#accession">JSONModel(:accession) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}




## DELETE /repositories/:repo_id/accessions/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/accessions/1'
```

__Description__

Delete an Accession

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## GET /repositories/:repo_id/accessions/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/accessions/1'
```

__Description__

Get an Accession by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:accession)




## POST /repositories/:repo_id/accessions/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/accessions/1'
```

__Description__

Update an Accession

__Parameters__


	Integer id -- The ID of the record

  <a href="#accession">JSONModel(:accession) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /repositories/:repo_id/accessions/:id/suppressed 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/accessions/1/suppressed'
```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## POST /repositories/:repo_id/accessions/:id/transfer 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/accessions/1/transfer'
```

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved




## GET /repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_contexts/corporate_entities/1.:fmt/metadata'
```

__Description__

Get metadata for an EAC-CPF export of a corporate entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/archival_contexts/corporate_entities/:id.xml 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_contexts/corporate_entities/1.xml'
```

__Description__

Get an EAC-CPF representation of a Corporate Entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)




## GET /repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_contexts/families/1.:fmt/metadata'
```

__Description__

Get metadata for an EAC-CPF export of a family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/archival_contexts/families/:id.xml 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_contexts/families/1.xml'
```

__Description__

Get an EAC-CPF representation of a Family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)




## GET /repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_contexts/people/1.:fmt/metadata'
```

__Description__

Get metadata for an EAC-CPF export of a person

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/archival_contexts/people/:id.xml 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_contexts/people/1.xml'
```

__Description__

Get an EAC-CPF representation of an Agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)




## GET /repositories/:repo_id/archival_contexts/softwares/:id.:fmt/metadata 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_contexts/softwares/1.:fmt/metadata'
```

__Description__

Get metadata for an EAC-CPF export of a software

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/archival_contexts/softwares/:id.xml 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_contexts/softwares/1.xml'
```

__Description__

Get an EAC-CPF representation of a Software agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)




## POST /repositories/:repo_id/archival_objects 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/archival_objects'
```

__Description__

Create an Archival Object

__Parameters__


  <a href="#archival_object">JSONModel(:archival_object) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/archival_objects 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_objects?page=1'
```

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




## DELETE /repositories/:repo_id/archival_objects/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/archival_objects/1'
```

__Description__

Delete an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## POST /repositories/:repo_id/archival_objects/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/archival_objects/1'
```

__Description__

Update an Archival Object

__Parameters__


	Integer id -- The ID of the record

  <a href="#archival_object">JSONModel(:archival_object) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/archival_objects/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_objects/1'
```

__Description__

Get an Archival Object by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:archival_object)
	404 -- Not found




## POST /repositories/:repo_id/archival_objects/:id/accept_children 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/archival_objects/1/accept_children'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/archival_objects/1/children'
```

__Description__

Batch create several Archival Objects as children of an existing Archival Object

__Parameters__


  <a href="#archival_record_children">JSONModel(:archival_record_children) <request body> -- The children to add to the archival object</a>

	Integer id -- The ID of the archival object to add children to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}




## GET /repositories/:repo_id/archival_objects/:id/children 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/archival_objects/1/children'
```

__Description__

Get the children of an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of archival object references
	404 -- Not found




## POST /repositories/:repo_id/archival_objects/:id/parent 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/archival_objects/1/parent'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/archival_objects/1/suppressed'
```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## POST /repositories/:repo_id/batch_imports 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d Q524VPF  
 'http://localhost:8089/repositories/:repo_id/batch_imports'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/classification_terms?page=1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/classification_terms'
```

__Description__

Create a Classification Term

__Parameters__


  <a href="#classification_term">JSONModel(:classification_term) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## POST /repositories/:repo_id/classification_terms/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/classification_terms/1'
```

__Description__

Update a Classification Term

__Parameters__


	Integer id -- The ID of the record

  <a href="#classification_term">JSONModel(:classification_term) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## DELETE /repositories/:repo_id/classification_terms/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/classification_terms/1'
```

__Description__

Delete a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## GET /repositories/:repo_id/classification_terms/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/classification_terms/1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/classification_terms/1/accept_children'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/classification_terms/1/children'
```

__Description__

Get the children of a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of classification term references
	404 -- Not found




## POST /repositories/:repo_id/classification_terms/:id/parent 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/classification_terms/1/parent'
```

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




## POST /repositories/:repo_id/classifications 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/classifications'
```

__Description__

Create a Classification

__Parameters__


  <a href="#classification">JSONModel(:classification) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/classifications 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/classifications?page=1'
```

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




## DELETE /repositories/:repo_id/classifications/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/classifications/1'
```

__Description__

Delete a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## POST /repositories/:repo_id/classifications/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/classifications/1'
```

__Description__

Update a Classification

__Parameters__


	Integer id -- The ID of the record

  <a href="#classification">JSONModel(:classification) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/classifications/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/classifications/1'
```

__Description__

Get a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:classification)




## POST /repositories/:repo_id/classifications/:id/accept_children 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/classifications/1/accept_children'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/classifications/1/tree'
```

__Description__

Get a Classification tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK




## POST /repositories/:repo_id/component_transfers 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/component_transfers'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/current_preferences'
```

__Description__

Get the Preferences records for the current repository and user.

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {(:preference)}




## GET /repositories/:repo_id/default_values/:record_type 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/default_values/:record_type'
```

__Description__

Get default values for a record type

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## POST /repositories/:repo_id/default_values/:record_type 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d JF681N373  
 'http://localhost:8089/repositories/:repo_id/default_values/:record_type'
```

__Description__

Save defaults for a record type

__Parameters__


  <a href="#default_values">JSONModel(:default_values) <request body> -- The default values set</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## POST /repositories/:repo_id/digital_object_components 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/digital_object_components'
```

__Description__

Create an Digital Object Component

__Parameters__


  <a href="#digital_object_component">JSONModel(:digital_object_component) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/digital_object_components 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_object_components?page=1'
```

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




## POST /repositories/:repo_id/digital_object_components/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/digital_object_components/1'
```

__Description__

Update an Digital Object Component

__Parameters__


	Integer id -- The ID of the record

  <a href="#digital_object_component">JSONModel(:digital_object_component) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## DELETE /repositories/:repo_id/digital_object_components/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/digital_object_components/1'
```

__Description__

Delete a Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## GET /repositories/:repo_id/digital_object_components/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_object_components/1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/digital_object_components/1/accept_children'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/digital_object_components/1/children'
```

__Description__

Batch create several Digital Object Components as children of an existing Digital Object Component

__Parameters__


  <a href="#digital_record_children">JSONModel(:digital_record_children) <request body> -- The children to add to the digital object component</a>

	Integer id -- The ID of the digital object component to add children to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}




## GET /repositories/:repo_id/digital_object_components/:id/children 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_object_components/1/children'
```

__Description__

Get the children of an Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object_component)]
	404 -- Not found




## POST /repositories/:repo_id/digital_object_components/:id/parent 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/digital_object_components/1/parent'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/digital_object_components/1/suppressed'
```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## POST /repositories/:repo_id/digital_objects 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/digital_objects'
```

__Description__

Create a Digital Object

__Parameters__


  <a href="#digital_object">JSONModel(:digital_object) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/digital_objects 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_objects?page=1'
```

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




## GET /repositories/:repo_id/digital_objects/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_objects/1'
```

__Description__

Get a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:digital_object)




## POST /repositories/:repo_id/digital_objects/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/digital_objects/1'
```

__Description__

Update a Digital Object

__Parameters__


	Integer id -- The ID of the record

  <a href="#digital_object">JSONModel(:digital_object) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## DELETE /repositories/:repo_id/digital_objects/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/digital_objects/1'
```

__Description__

Delete a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## POST /repositories/:repo_id/digital_objects/:id/accept_children 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/digital_objects/1/accept_children'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/digital_objects/1/children'
```

__Description__

Batch create several Digital Object Components as children of an existing Digital Object

__Parameters__


  <a href="#digital_record_children">JSONModel(:digital_record_children) <request body> -- The component children to add to the digital object</a>

	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}




## POST /repositories/:repo_id/digital_objects/:id/publish 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/digital_objects/1/publish'
```

__Description__

Publish a digital object and all its sub-records and components

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## POST /repositories/:repo_id/digital_objects/:id/suppressed 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/digital_objects/1/suppressed'
```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## POST /repositories/:repo_id/digital_objects/:id/transfer 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/digital_objects/1/transfer'
```

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved




## GET /repositories/:repo_id/digital_objects/:id/tree 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_objects/1/tree'
```

__Description__

Get a Digital Object tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK




## GET /repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_objects/dublin_core/1.:fmt/metadata'
```

__Description__

Get metadata for a Dublin Core export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/digital_objects/dublin_core/:id.xml 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_objects/dublin_core/1.xml'
```

__Description__

Get a Dublin Core representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)




## GET /repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_objects/mets/1.:fmt/metadata'
```

__Description__

Get metadata for a METS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/digital_objects/mets/:id.xml 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_objects/mets/1.xml'
```

__Description__

Get a METS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)




## GET /repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_objects/mods/1.:fmt/metadata'
```

__Description__

Get metadata for a MODS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/digital_objects/mods/:id.xml 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/digital_objects/mods/1.xml'
```

__Description__

Get a MODS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)




## POST /repositories/:repo_id/events 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/events'
```

__Description__

Create an Event

__Parameters__


  <a href="#event">JSONModel(:event) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/events 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/events?page=1'
```

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




## DELETE /repositories/:repo_id/events/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/events/1'
```

__Description__

Delete an event record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## GET /repositories/:repo_id/events/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/events/1'
```

__Description__

Get an Event by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:event)
	404 -- Not found




## POST /repositories/:repo_id/events/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/events/1'
```

__Description__

Update an Event

__Parameters__


	Integer id -- The ID of the record

  <a href="#event">JSONModel(:event) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /repositories/:repo_id/events/:id/suppressed 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/events/1/suppressed'
```

__Description__

Suppress this record from non-managers

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## GET /repositories/:repo_id/find_by_id/archival_objects 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/find_by_id/archival_objects'
```

__Description__

Find Archival Objects by ref_id or component_id

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] ref_id -- A set of record Ref IDs

	[String] component_id -- A set of record component IDs

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- JSON array of refs




## GET /repositories/:repo_id/find_by_id/digital_object_components 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/find_by_id/digital_object_components'
```

__Description__

Find Digital Object Components by component_id

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] component_id -- A set of record component IDs

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- JSON array of refs




## GET /repositories/:repo_id/groups 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/groups'
```

__Description__

Get a list of groups for a repository

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String group_code -- Get groups by group code

__Returns__

	200 -- [(:resource)]




## POST /repositories/:repo_id/groups 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/groups'
```

__Description__

Create a group within a repository

__Parameters__


  <a href="#group">JSONModel(:group) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- conflict




## DELETE /repositories/:repo_id/groups/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/groups/1'
```

__Description__

Delete a group by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:group)
	404 -- Not found




## GET /repositories/:repo_id/groups/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/groups/1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d BooleanParam  
 'http://localhost:8089/repositories/:repo_id/groups/1'
```

__Description__

Update a group

__Parameters__


	Integer id -- The ID of the record

  <a href="#group">JSONModel(:group) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam with_members -- If 'true' (the default) replace the membership list with the list provided

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}
	409 -- conflict




## POST /repositories/:repo_id/jobs 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/jobs'
```

__Description__

Create a new import job

__Parameters__


  <a href="#job">JSONModel(:job) <request body> -- The job object</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /repositories/:repo_id/jobs 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs?page=1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs/1'
```

__Description__

Get a Job by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:job)




## POST /repositories/:repo_id/jobs/:id/cancel 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/jobs/1/cancel'
```

__Description__

Cancel a job

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /repositories/:repo_id/jobs/:id/log 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs/1/log'
```

__Description__

Get a Job's log by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::NonNegativeInteger offset -- The byte offset of the log file to show

__Returns__

	200 -- The section of the import log between 'offset' and the end of file




## GET /repositories/:repo_id/jobs/:id/output_files 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs/1/output_files'
```

__Description__

Get a list of Job's output files by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- An array of output files




## GET /repositories/:repo_id/jobs/:id/output_files/:file_id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs/1/output_files/:file_id'
```

__Description__

Get a Job's output file by ID

__Parameters__


	Integer id -- The ID of the record

	Integer file_id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- Returns the file




## GET /repositories/:repo_id/jobs/:id/records 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs/1/records?page=1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs/active'
```

__Description__

Get a list of all active Jobs for a Repository

__Parameters__


	[String] resolve -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:job)]




## GET /repositories/:repo_id/jobs/archived 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs/archived?page=1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs/import_types'
```

__Description__

List all supported import job types

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- A list of supported import types




## GET /repositories/:repo_id/jobs/types 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/jobs/types'
```

__Description__

List all supported import job types

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- A list of supported job types




## POST /repositories/:repo_id/jobs_with_files 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/jobs_with_files'
```

__Description__

Create a new import job and post input files

__Parameters__


	JSONModel(:job) job -- 

	[RESTHelpers::UploadFile] files -- 

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /repositories/:repo_id/preferences 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/preferences'
```

__Description__

Create a Preferences record

__Parameters__


  <a href="#preference">JSONModel(:preference) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/preferences 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/preferences'
```

__Description__

Get a list of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer user_id -- The username to retrieve defaults for

__Returns__

	200 -- [(:preference)]




## GET /repositories/:repo_id/preferences/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/preferences/1'
```

__Description__

Get a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:preference)




## DELETE /repositories/:repo_id/preferences/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/preferences/1'
```

__Description__

Delete a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## POST /repositories/:repo_id/preferences/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/preferences/1'
```

__Description__

Update a Preferences record

__Parameters__


	Integer id -- The ID of the record

  <a href="#preference">JSONModel(:preference) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/preferences/defaults 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/preferences/defaults'
```

__Description__

Get the default set of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String username -- The username to retrieve defaults for

__Returns__

	200 -- (defaults)




## POST /repositories/:repo_id/rde_templates 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/rde_templates'
```

__Description__

Create an RDE template

__Parameters__


  <a href="#rde_template">JSONModel(:rde_template) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/rde_templates 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/rde_templates'
```

__Description__

Get a list of RDE Templates

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:rde_template)]




## GET /repositories/:repo_id/rde_templates/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/rde_templates/1'
```

__Description__

Get an RDE template record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:rde_template)




## DELETE /repositories/:repo_id/rde_templates/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/rde_templates/1'
```

__Description__

Delete an RDE Template

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## GET /repositories/:repo_id/resource_descriptions/:id.:fmt/metadata 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resource_descriptions/1.:fmt/metadata'
```

__Description__

Get export metadata for a Resource Description

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	String fmt -- Format of the request

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/resource_descriptions/:id.pdf 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resource_descriptions/1.pdf'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resource_descriptions/1.xml'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resource_labels/1.:fmt/metadata'
```

__Description__

Get export metadata for Resource labels

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/resource_labels/:id.tsv 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resource_labels/1.tsv'
```

__Description__

Get a tsv list of printable labels for a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)




## POST /repositories/:repo_id/resources 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/resources'
```

__Description__

Create a Resource

__Parameters__


  <a href="#resource">JSONModel(:resource) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /repositories/:repo_id/resources 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resources?page=1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resources/1'
```

__Description__

Get a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:resource)




## POST /repositories/:repo_id/resources/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/resources/1'
```

__Description__

Update a Resource

__Parameters__


	Integer id -- The ID of the record

  <a href="#resource">JSONModel(:resource) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## DELETE /repositories/:repo_id/resources/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/resources/1'
```

__Description__

Delete a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## POST /repositories/:repo_id/resources/:id/accept_children 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/resources/1/accept_children'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/resources/1/children'
```

__Description__

Batch create several Archival Objects as children of an existing Resource

__Parameters__


  <a href="#archival_record_children">JSONModel(:archival_record_children) <request body> -- The children to add to the resource</a>

	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}




## GET /repositories/:repo_id/resources/:id/models_in_graph 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resources/1/models_in_graph'
```

__Description__

Get a list of record types in the graph of a resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK




## POST /repositories/:repo_id/resources/:id/publish 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/resources/1/publish'
```

__Description__

Publish a resource and all its sub-records and components

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## POST /repositories/:repo_id/resources/:id/suppressed 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/resources/1/suppressed'
```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## POST /repositories/:repo_id/resources/:id/transfer 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/resources/1/transfer'
```

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved




## GET /repositories/:repo_id/resources/:id/tree 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resources/1/tree'
```

__Description__

Get a Resource tree

__Parameters__


	Integer id -- The ID of the record

	String limit_to -- An Archival Object URI or 'root'

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK




## GET /repositories/:repo_id/resources/marc21/:id.:fmt/metadata 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resources/marc21/1.:fmt/metadata'
```

__Description__

Get metadata for a MARC21 export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata




## GET /repositories/:repo_id/resources/marc21/:id.xml 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/resources/marc21/1.xml'
```

__Description__

Get a MARC 21 representation of a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)




## GET /repositories/:repo_id/search 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/search?page=1'
```

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

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

__Returns__

	200 -- 




## POST /repositories/:repo_id/top_containers 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/top_containers'
```

__Description__

Create a top container

__Parameters__


  <a href="#top_container">JSONModel(:top_container) <request body> -- The record to create</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}




## GET /repositories/:repo_id/top_containers 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/top_containers?page=1'
```

__Description__

Get a list of TopContainers for a Repository

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

	200 -- [(:top_container)]




## POST /repositories/:repo_id/top_containers/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/:repo_id/top_containers/1'
```

__Description__

Update a top container

__Parameters__


	Integer id -- The ID of the record

  <a href="#top_container">JSONModel(:top_container) <request body> -- The updated record</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /repositories/:repo_id/top_containers/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/top_containers/1'
```

__Description__

Get a top container by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:top_container)




## DELETE /repositories/:repo_id/top_containers/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/repositories/:repo_id/top_containers/1'
```

__Description__

Delete a top container

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted




## POST /repositories/:repo_id/top_containers/batch/container_profile 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/top_containers/batch/container_profile'
```

__Description__

Update container profile for a batch of top containers

__Parameters__


	[Integer] ids -- 

	String container_profile_uri -- The uri of the container profile

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /repositories/:repo_id/top_containers/batch/ils_holding_id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/top_containers/batch/ils_holding_id'
```

__Description__

Update ils_holding_id for a batch of top containers

__Parameters__


	[Integer] ids -- 

	String ils_holding_id -- Value to set for ils_holding_id

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /repositories/:repo_id/top_containers/batch/location 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/top_containers/batch/location'
```

__Description__

Update location for a batch of top containers

__Parameters__


	[Integer] ids -- 

	String location_uri -- The uri of the location

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## POST /repositories/:repo_id/top_containers/bulk/barcodes 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/top_containers/bulk/barcodes'
```

__Description__

Bulk update barcodes

__Parameters__


  <a href="#String">String <request body> -- JSON string containing barcode data {uri=>barcode}</a>

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /repositories/:repo_id/top_containers/search 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/top_containers/search'
```

__Description__

Search for top containers

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String q -- A search query string

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

__Returns__

	200 -- [(:top_container)]




## POST /repositories/:repo_id/transfer 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d 1  
 'http://localhost:8089/repositories/:repo_id/transfer'
```

__Description__

Transfer this record to a different repository

__Parameters__


	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved




## GET /repositories/:repo_id/users/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/:repo_id/users/1'
```

__Description__

Get a user's details including their groups for the current repository

__Parameters__


	Integer id -- The username id to fetch

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:user)




## POST /repositories/with_agent 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "repository_with_agent",
  "repository": {
    "jsonmodel_type": "repository",
    "name": "Description: 12",
    "repo_code": "ASPACE REPO 3 -- 83816",
    "org_code": "BJ26310812",
    "image_url": "http://www.example-5.com",
    "url": "http://www.example-6.com"
  },
  "agent_representation": {
    "jsonmodel_type": "agent_corporate_entity",
    "agent_contacts": [
      {
        "jsonmodel_type": "agent_contact",
        "telephones": [
          {
            "jsonmodel_type": "telephone",
            "number_type": "cell",
            "number": "53384 68481 03307 458 18032",
            "ext": "548FJB643"
          }
        ],
        "name": "Name Number 15",
        "address_2": "253HWNA",
        "address_3": "MWGQ694",
        "region": "R18028PD",
        "country": "590811QWW",
        "fax": "PDT154I",
        "note": "429448XUH"
      }
    ],
    "linked_agent_roles": [

    ],
    "external_documents": [

    ],
    "rights_statements": [

    ],
    "notes": [

    ],
    "dates_of_existence": [
      {
        "jsonmodel_type": "date",
        "date_type": "bulk",
        "label": "existence",
        "begin": "1981-08-13",
        "end": "1981-08-13",
        "expression": "PTTA946"
      }
    ],
    "names": [
      {
        "jsonmodel_type": "name_corporate_entity",
        "use_dates": [

        ],
        "authorized": false,
        "is_display_name": false,
        "sort_name_auto_generate": true,
        "rules": "rda",
        "primary_name": "Name Number 14",
        "subordinate_name_1": "L171484GE",
        "subordinate_name_2": "B834217562G",
        "number": "264WXB399",
        "sort_name": "SORT l - 11",
        "dates": "285385KEY",
        "qualifier": "N906ENG"
      }
    ],
    "related_agents": [

    ],
    "agent_type": "agent_corporate_entity"
  }
}  
 'http://localhost:8089/repositories/with_agent'
```

__Description__

Create a Repository with an agent representation

__Parameters__


  <a href="#repository_with_agent">JSONModel(:repository_with_agent) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	403 -- access_denied




## POST /repositories/with_agent/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/repositories/with_agent/1'
```

__Description__

Update a repository with an agent representation

__Parameters__


	Integer id -- The ID of the record

  <a href="#repository_with_agent">JSONModel(:repository_with_agent) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /repositories/with_agent/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/repositories/with_agent/1'
```

__Description__

Get a Repository by ID, including its agent representation

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:repository_with_agent)
	404 -- Not found




## GET /search 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/search?page=1'
```

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

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

__Returns__

	200 -- 




## GET /search/published_tree 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/search/published_tree'
```

__Description__

Find the tree view for a particular archival record

__Parameters__


	String node_uri -- The URI of the archival record to find the tree view for

__Returns__

	200 -- OK
	404 -- Not found




## GET /search/repositories 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/search/repositories?page=1'
```

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

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

__Returns__

	200 -- 




## GET /search/subjects 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/search/subjects?page=1'
```

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

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

__Returns__

	200 -- 




## POST /subjects 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "subject",
  "external_ids": [

  ],
  "publish": true,
  "terms": [
    {
      "jsonmodel_type": "term",
      "term": "Term 1",
      "term_type": "technique",
      "vocabulary": "/vocabularies/2"
    }
  ],
  "external_documents": [

  ],
  "vocabulary": "/vocabularies/3",
  "authority_id": "http://www.example-7.com",
  "scope_note": "NR888166E",
  "source": "gmgpc"
}  
 'http://localhost:8089/subjects'
```

__Description__

Create a Subject

__Parameters__


  <a href="#subject">JSONModel(:subject) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}




## GET /subjects 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/subjects?page=1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/subjects/1'
```

__Description__

Delete a Subject

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted




## GET /subjects/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/subjects/1'
```

__Description__

Get a Subject by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:subject)




## POST /subjects/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "subject",
  "external_ids": [

  ],
  "publish": true,
  "terms": [
    {
      "jsonmodel_type": "term",
      "term": "Term 1",
      "term_type": "technique",
      "vocabulary": "/vocabularies/2"
    }
  ],
  "external_documents": [

  ],
  "vocabulary": "/vocabularies/3",
  "authority_id": "http://www.example-7.com",
  "scope_note": "NR888166E",
  "source": "gmgpc"
}  
 'http://localhost:8089/subjects/1'
```

__Description__

Update a Subject

__Parameters__


	Integer id -- The ID of the record

  <a href="#subject">JSONModel(:subject) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /terms 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/terms'
```

__Description__

Get a list of Terms matching a prefix

__Parameters__


	String q -- The prefix to match

__Returns__

	200 -- [(:term)]




## GET /update-feed 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/update-feed'
```

__Description__

Get a stream of updated records

__Parameters__


	Integer last_sequence -- The last sequence number seen

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- a list of records and sequence numbers




## POST /update_monitor 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "active_edits",
  "active_edits": [
    {
      "user": "PK994JL",
      "uri": "TOBLQ",
      "time": "2015-12-16T18:57:34+01:00"
    }
  ]
}  
 'http://localhost:8089/update_monitor'
```

__Description__

Refresh the list of currently known edits

__Parameters__


  <a href="#active_edits">JSONModel(:active_edits) <request body> -- The list of active edits</a>

__Returns__

	200 -- A list of records, the user editing it and the lock version for each




## POST /users 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/users'
```

__Description__

Create a local user

__Parameters__


	String password -- The user's password

	[String] groups -- Array of groups URIs to assign the user to

  <a href="#user">JSONModel(:user) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}




## GET /users 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/users?page=1'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -X DELETE 
 'http://localhost:8089/users/1'
```

__Description__

Delete a user

__Parameters__


	Integer id -- The user to delete

__Returns__

	200 -- deleted




## GET /users/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/users/1'
```

__Description__

Get a user's details (including their current permissions)

__Parameters__


	Integer id -- The username id to fetch

__Returns__

	200 -- (:user)




## POST /users/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/users/1'
```

__Description__

Update a user's account

__Parameters__


	Integer id -- The ID of the record

	String password -- The user's password

	[String] groups -- Array of groups URIs to assign the user to

	RESTHelpers::BooleanParam remove_groups -- Remove all groups from the user for the current repo_id if true

	Integer repo_id -- The Repository groups to clear

  <a href="#user">JSONModel(:user) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}




## POST /users/:username/become-user 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d username_2  
 'http://localhost:8089/users/:username/become-user'
```

__Description__

Become a different user

__Parameters__


	Username username -- The username to become

__Returns__

	200 -- Accepted
	404 -- User not found




## POST /users/:username/login 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d BooleanParam  
 'http://localhost:8089/users/:username/login'
```

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

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/users/complete'
```

__Description__

Get a list of system users

__Parameters__


	String query -- A prefix to search for

__Returns__

	200 -- A list of usernames




## GET /users/current-user 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/users/current-user'
```

__Description__

Get the currently logged in user

__Parameters__


__Returns__

	200 -- (:user)
	404 -- Not logged in




## GET /version 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/version'
```

__Description__

Get the ArchivesSpace application version

__Parameters__


__Returns__

	200 -- ArchivesSpace (version)




## POST /vocabularies 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d   
 'http://localhost:8089/vocabularies'
```

__Description__

Create a Vocabulary

__Parameters__


  <a href="#vocabulary">JSONModel(:vocabulary) <request body> -- The record to create</a>

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}




## GET /vocabularies 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/vocabularies'
```

__Description__

Get a list of Vocabularies

__Parameters__


	String ref_id -- An alternate, externally-created ID for the vocabulary

__Returns__

	200 -- [(:vocabulary)]




## POST /vocabularies/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 -d {
  "jsonmodel_type": "vocabulary",
  "terms": [

  ],
  "name": "Vocabulary 4 - 2015-12-16 18:57:37 +0100",
  "ref_id": "vocab_ref_4 - 2015-12-16 18:57:37 +0100"
}  
 'http://localhost:8089/vocabularies/1'
```

__Description__

Update a Vocabulary

__Parameters__


	Integer id -- The ID of the record

  <a href="#vocabulary">JSONModel(:vocabulary) <request body> -- The updated record</a>

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}




## GET /vocabularies/:id 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/vocabularies/1'
```

__Description__

Get a Vocabulary by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- OK




## GET /vocabularies/:id/terms 

> Example Request:

```shell
curl -H "X-ArchivesSpace-Session: $SESSION"  
 'http://localhost:8089/vocabularies/1/terms'
```

__Description__

Get a list of Terms for a Vocabulary

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- [(:term)]




# Schemas


##  <a id="abstract_agent" ></a> JSONModel(:abstract_agent) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/abstract_agent.json">      
</script>


##  <a id="abstract_agent_relationship" ></a> JSONModel(:abstract_agent_relationship) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/abstract_agent_relationship.json">      
</script>


##  <a id="abstract_archival_object" ></a> JSONModel(:abstract_archival_object) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/abstract_archival_object.json">      
</script>


##  <a id="abstract_classification" ></a> JSONModel(:abstract_classification) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/abstract_classification.json">      
</script>


##  <a id="abstract_name" ></a> JSONModel(:abstract_name) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/abstract_name.json">      
</script>


##  <a id="abstract_note" ></a> JSONModel(:abstract_note) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/abstract_note.json">      
</script>


##  <a id="accession" ></a> JSONModel(:accession) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/accession.json">      
</script>


##  <a id="accession_parts_relationship" ></a> JSONModel(:accession_parts_relationship) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/accession_parts_relationship.json">      
</script>


##  <a id="accession_sibling_relationship" ></a> JSONModel(:accession_sibling_relationship) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/accession_sibling_relationship.json">      
</script>


##  <a id="active_edits" ></a> JSONModel(:active_edits) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/active_edits.json">      
</script>


##  <a id="advanced_query" ></a> JSONModel(:advanced_query) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/advanced_query.json">      
</script>


##  <a id="agent_contact" ></a> JSONModel(:agent_contact) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/agent_contact.json">      
</script>


##  <a id="agent_corporate_entity" ></a> JSONModel(:agent_corporate_entity) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/agent_corporate_entity.json">      
</script>


##  <a id="agent_family" ></a> JSONModel(:agent_family) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/agent_family.json">      
</script>


##  <a id="agent_person" ></a> JSONModel(:agent_person) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/agent_person.json">      
</script>


##  <a id="agent_relationship_associative" ></a> JSONModel(:agent_relationship_associative) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/agent_relationship_associative.json">      
</script>


##  <a id="agent_relationship_earlierlater" ></a> JSONModel(:agent_relationship_earlierlater) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/agent_relationship_earlierlater.json">      
</script>


##  <a id="agent_relationship_parentchild" ></a> JSONModel(:agent_relationship_parentchild) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/agent_relationship_parentchild.json">      
</script>


##  <a id="agent_relationship_subordinatesuperior" ></a> JSONModel(:agent_relationship_subordinatesuperior) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/agent_relationship_subordinatesuperior.json">      
</script>


##  <a id="agent_software" ></a> JSONModel(:agent_software) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/agent_software.json">      
</script>


##  <a id="archival_object" ></a> JSONModel(:archival_object) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/archival_object.json">      
</script>


##  <a id="archival_record_children" ></a> JSONModel(:archival_record_children) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/archival_record_children.json">      
</script>


##  <a id="boolean_field_query" ></a> JSONModel(:boolean_field_query) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/boolean_field_query.json">      
</script>


##  <a id="boolean_query" ></a> JSONModel(:boolean_query) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/boolean_query.json">      
</script>


##  <a id="classification" ></a> JSONModel(:classification) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/classification.json">      
</script>


##  <a id="classification_term" ></a> JSONModel(:classification_term) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/classification_term.json">      
</script>


##  <a id="record_tree" ></a> JSONModel(:record_tree) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/record_tree.json">      
</script>


##  <a id="classification_tree" ></a> JSONModel(:classification_tree) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/classification_tree.json">      
</script>


##  <a id="collection_management" ></a> JSONModel(:collection_management) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/collection_management.json">      
</script>


##  <a id="container" ></a> JSONModel(:container) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/container.json">      
</script>


##  <a id="container_location" ></a> JSONModel(:container_location) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/container_location.json">      
</script>


##  <a id="container_profile" ></a> JSONModel(:container_profile) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/container_profile.json">      
</script>


##  <a id="date" ></a> JSONModel(:date) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/date.json">      
</script>


##  <a id="date_field_query" ></a> JSONModel(:date_field_query) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/date_field_query.json">      
</script>


##  <a id="deaccession" ></a> JSONModel(:deaccession) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/deaccession.json">      
</script>


##  <a id="default_values" ></a> JSONModel(:default_values) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/default_values.json">      
</script>


##  <a id="defaults" ></a> JSONModel(:defaults) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/defaults.json">      
</script>


##  <a id="digital_object" ></a> JSONModel(:digital_object) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/digital_object.json">      
</script>


##  <a id="digital_object_component" ></a> JSONModel(:digital_object_component) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/digital_object_component.json">      
</script>


##  <a id="digital_object_tree" ></a> JSONModel(:digital_object_tree) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/digital_object_tree.json">      
</script>


##  <a id="digital_record_children" ></a> JSONModel(:digital_record_children) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/digital_record_children.json">      
</script>


##  <a id="enumeration" ></a> JSONModel(:enumeration) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/enumeration.json">      
</script>


##  <a id="enumeration_migration" ></a> JSONModel(:enumeration_migration) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/enumeration_migration.json">      
</script>


##  <a id="enumeration_value" ></a> JSONModel(:enumeration_value) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/enumeration_value.json">      
</script>


##  <a id="event" ></a> JSONModel(:event) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/event.json">      
</script>


##  <a id="extent" ></a> JSONModel(:extent) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/extent.json">      
</script>


##  <a id="external_document" ></a> JSONModel(:external_document) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/external_document.json">      
</script>


##  <a id="external_id" ></a> JSONModel(:external_id) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/external_id.json">      
</script>


##  <a id="field_query" ></a> JSONModel(:field_query) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/field_query.json">      
</script>


##  <a id="file_version" ></a> JSONModel(:file_version) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/file_version.json">      
</script>


##  <a id="find_and_replace_job" ></a> JSONModel(:find_and_replace_job) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/find_and_replace_job.json">      
</script>


##  <a id="group" ></a> JSONModel(:group) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/group.json">      
</script>


##  <a id="import_job" ></a> JSONModel(:import_job) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/import_job.json">      
</script>


##  <a id="instance" ></a> JSONModel(:instance) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/instance.json">      
</script>


##  <a id="job" ></a> JSONModel(:job) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/job.json">      
</script>


##  <a id="location" ></a> JSONModel(:location) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/location.json">      
</script>


##  <a id="location_batch" ></a> JSONModel(:location_batch) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/location_batch.json">      
</script>


##  <a id="location_batch_update" ></a> JSONModel(:location_batch_update) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/location_batch_update.json">      
</script>


##  <a id="merge_request" ></a> JSONModel(:merge_request) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/merge_request.json">      
</script>


##  <a id="name_corporate_entity" ></a> JSONModel(:name_corporate_entity) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/name_corporate_entity.json">      
</script>


##  <a id="name_family" ></a> JSONModel(:name_family) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/name_family.json">      
</script>


##  <a id="name_form" ></a> JSONModel(:name_form) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/name_form.json">      
</script>


##  <a id="name_person" ></a> JSONModel(:name_person) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/name_person.json">      
</script>


##  <a id="name_software" ></a> JSONModel(:name_software) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/name_software.json">      
</script>


##  <a id="note_abstract" ></a> JSONModel(:note_abstract) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_abstract.json">      
</script>


##  <a id="note_bibliography" ></a> JSONModel(:note_bibliography) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_bibliography.json">      
</script>


##  <a id="note_bioghist" ></a> JSONModel(:note_bioghist) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_bioghist.json">      
</script>


##  <a id="note_chronology" ></a> JSONModel(:note_chronology) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_chronology.json">      
</script>


##  <a id="note_citation" ></a> JSONModel(:note_citation) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_citation.json">      
</script>


##  <a id="note_definedlist" ></a> JSONModel(:note_definedlist) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_definedlist.json">      
</script>


##  <a id="note_digital_object" ></a> JSONModel(:note_digital_object) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_digital_object.json">      
</script>


##  <a id="note_index" ></a> JSONModel(:note_index) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_index.json">      
</script>


##  <a id="note_index_item" ></a> JSONModel(:note_index_item) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_index_item.json">      
</script>


##  <a id="note_multipart" ></a> JSONModel(:note_multipart) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_multipart.json">      
</script>


##  <a id="note_orderedlist" ></a> JSONModel(:note_orderedlist) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_orderedlist.json">      
</script>


##  <a id="note_outline" ></a> JSONModel(:note_outline) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_outline.json">      
</script>


##  <a id="note_outline_level" ></a> JSONModel(:note_outline_level) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_outline_level.json">      
</script>


##  <a id="note_singlepart" ></a> JSONModel(:note_singlepart) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_singlepart.json">      
</script>


##  <a id="note_text" ></a> JSONModel(:note_text) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/note_text.json">      
</script>


##  <a id="permission" ></a> JSONModel(:permission) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/permission.json">      
</script>


##  <a id="preference" ></a> JSONModel(:preference) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/preference.json">      
</script>


##  <a id="print_to_pdf_job" ></a> JSONModel(:print_to_pdf_job) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/print_to_pdf_job.json">      
</script>


##  <a id="rde_template" ></a> JSONModel(:rde_template) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/rde_template.json">      
</script>


##  <a id="report_job" ></a> JSONModel(:report_job) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/report_job.json">      
</script>


##  <a id="repository" ></a> JSONModel(:repository) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/repository.json">      
</script>


##  <a id="repository_with_agent" ></a> JSONModel(:repository_with_agent) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/repository_with_agent.json">      
</script>


##  <a id="resource" ></a> JSONModel(:resource) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/resource.json">      
</script>


##  <a id="resource_tree" ></a> JSONModel(:resource_tree) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/resource_tree.json">      
</script>


##  <a id="revision_statement" ></a> JSONModel(:revision_statement) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/revision_statement.json">      
</script>


##  <a id="rights_restriction" ></a> JSONModel(:rights_restriction) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/rights_restriction.json">      
</script>


##  <a id="rights_statement" ></a> JSONModel(:rights_statement) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/rights_statement.json">      
</script>


##  <a id="sub_container" ></a> JSONModel(:sub_container) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/sub_container.json">      
</script>


##  <a id="subject" ></a> JSONModel(:subject) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/subject.json">      
</script>


##  <a id="telephone" ></a> JSONModel(:telephone) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/telephone.json">      
</script>


##  <a id="term" ></a> JSONModel(:term) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/term.json">      
</script>


##  <a id="top_container" ></a> JSONModel(:top_container) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/top_container.json">      
</script>


##  <a id="user" ></a> JSONModel(:user) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/user.json">      
</script>


##  <a id="user_defined" ></a> JSONModel(:user_defined) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/user_defined.json">      
</script>


##  <a id="vocabulary" ></a> JSONModel(:vocabulary) 
<script src="/archivesspace/docson/widget.js" 
  data-schema="/archivesspace/schemas/vocabulary.json">      
</script>

