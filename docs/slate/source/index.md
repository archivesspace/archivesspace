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
As of 2017-02-15 10:09:29 -0500 the following REST endpoints exist in the master branch of the development repository:


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/corporate_entities?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/corporate_entities?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/corporate_entities?all_ids=true"
  

```


## POST /agents/corporate_entities 

__Description__

Create a corporate entity agent

__Parameters__


	JSONModel(:agent_corporate_entity) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number_type":"business",
"number":"606 216 167 3224"}],
"name":"Name Number 505",
"city":"RL702510Q",
"post_code":"A757C825I",
"email":"YFX590Q",
"email_signature":"FE628X813"}],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"1982-06-23",
"end":"1982-06-23",
"expression":"51O38397X"}],
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"primary_name":"Name Number 504",
"subordinate_name_1":"509330MYY",
"subordinate_name_2":"R961PD360",
"number":"VUMAI",
"sort_name":"SORT w - 422",
"dates":"949842890I189",
"qualifier":"VF7DL",
"authority_id":"http://www.example-468.com",
"source":"nad"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089//agents/corporate_entities"
  

```


## DELETE /agents/corporate_entities/:id 

__Description__

Delete a corporate entity agent

__Parameters__


	Integer id -- ID of the corporate entity agent

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//agents/corporate_entities/1"

```


## GET /agents/corporate_entities/:id 

__Description__

Get a corporate entity by ID

__Parameters__


	Integer id -- ID of the corporate entity agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent_corporate_entity)
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/corporate_entities/1"
  

```


## POST /agents/corporate_entities/:id 

__Description__

Update a corporate entity agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_corporate_entity) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number_type":"business",
"number":"606 216 167 3224"}],
"name":"Name Number 505",
"city":"RL702510Q",
"post_code":"A757C825I",
"email":"YFX590Q",
"email_signature":"FE628X813"}],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"1982-06-23",
"end":"1982-06-23",
"expression":"51O38397X"}],
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"primary_name":"Name Number 504",
"subordinate_name_1":"509330MYY",
"subordinate_name_2":"R961PD360",
"number":"VUMAI",
"sort_name":"SORT w - 422",
"dates":"949842890I189",
"qualifier":"VF7DL",
"authority_id":"http://www.example-468.com",
"source":"nad"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089//agents/corporate_entities/1"
  

```


## POST /agents/families 

__Description__

Create a family agent

__Parameters__


	JSONModel(:agent_family) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_family",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"1975-05-24",
"end":"1975-05-24",
"expression":"55K849MJ"}],
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"family_name":"Name Number 506",
"sort_name":"SORT d - 423",
"dates":"364P798MV",
"qualifier":"815551YIG",
"prefix":"435J425444289",
"authority_id":"http://www.example-469.com",
"source":"local"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089//agents/families"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/families?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/families?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/families?all_ids=true"
  

```


## POST /agents/families/:id 

__Description__

Update a family agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_family) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_family",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"1975-05-24",
"end":"1975-05-24",
"expression":"55K849MJ"}],
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"family_name":"Name Number 506",
"sort_name":"SORT d - 423",
"dates":"364P798MV",
"qualifier":"815551YIG",
"prefix":"435J425444289",
"authority_id":"http://www.example-469.com",
"source":"local"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089//agents/families/1"
  

```


## GET /agents/families/:id 

__Description__

Get a family by ID

__Parameters__


	Integer id -- ID of the family agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/families/1"
  

```


## DELETE /agents/families/:id 

__Description__

Delete an agent family

__Parameters__


	Integer id -- ID of the family agent

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//agents/families/1"

```


## POST /agents/people 

__Description__

Create a person agent

__Parameters__


	JSONModel(:agent_person) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_person",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"2002-07-23",
"end":"2002-07-23",
"expression":"SQA374D"}],
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"source":"nad",
"primary_name":"Name Number 507",
"sort_name":"SORT m - 424",
"name_order":"direct",
"number":"WAAYL",
"dates":"NMHSV",
"qualifier":"CIA622835",
"fuller_form":"A29954496O",
"title":"391864551V282",
"authority_id":"http://www.example-470.com"}],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089//agents/people"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/people?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/people?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/people?all_ids=true"
  

```


## POST /agents/people/:id 

__Description__

Update a person agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_person) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_person",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"2002-07-23",
"end":"2002-07-23",
"expression":"SQA374D"}],
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"source":"nad",
"primary_name":"Name Number 507",
"sort_name":"SORT m - 424",
"name_order":"direct",
"number":"WAAYL",
"dates":"NMHSV",
"qualifier":"CIA622835",
"fuller_form":"A29954496O",
"title":"391864551V282",
"authority_id":"http://www.example-470.com"}],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089//agents/people/1"
  

```


## GET /agents/people/:id 

__Description__

Get a person by ID

__Parameters__


	Integer id -- ID of the person agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/people/1"
  

```


## DELETE /agents/people/:id 

__Description__

Delete an agent person

__Parameters__


	Integer id -- ID of the person agent

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//agents/people/1"

```


## POST /agents/software 

__Description__

Create a software agent

__Parameters__


	JSONModel(:agent_software) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_software",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"2014-10-31",
"end":"2014-10-31",
"expression":"D820768OV"}],
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"software_name":"Name Number 508",
"sort_name":"SORT i - 425"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089//agents/software"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/software?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/software?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/software?all_ids=true"
  

```


## DELETE /agents/software/:id 

__Description__

Delete a software agent

__Parameters__


	Integer id -- ID of the software agent

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//agents/software/1"

```


## POST /agents/software/:id 

__Description__

Update a software agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_software) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_software",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"2014-10-31",
"end":"2014-10-31",
"expression":"D820768OV"}],
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"software_name":"Name Number 508",
"sort_name":"SORT i - 425"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089//agents/software/1"
  

```


## GET /agents/software/:id 

__Description__

Get a software agent by ID

__Parameters__


	Integer id -- ID of the software agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/software/1"
  

```


## POST /batch_delete 

__Description__

Carry out delete requests against a list of records

__Parameters__


	[String] record_uris -- A list of record uris

__Returns__

	200 -- deleted


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"304926HLE"' \
  "http://localhost:8089//batch_delete"
  

```


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


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/by-external-id"
  

```


## GET /config/enumeration_values/:enum_val_id 

__Description__

Get an Enumeration Value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to retrieve

__Returns__

	200 -- (:enumeration_value)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/config/enumeration_values/:enum_val_id"
  

```


## POST /config/enumeration_values/:enum_val_id 

__Description__

Update an enumeration value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	JSONModel(:enumeration_value) <request body> -- The enumeration value to update

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//config/enumeration_values/:enum_val_id"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//config/enumeration_values/:enum_val_id"
  

```


## POST /config/enumeration_values/:enum_val_id/position 

__Description__

Update the position of an ennumeration value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	Integer position -- The target position in the value list

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//config/enumeration_values/:enum_val_id/position"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//config/enumeration_values/:enum_val_id/position"
  

```


## POST /config/enumeration_values/:enum_val_id/suppressed 

__Description__

Suppress this value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	RESTHelpers::BooleanParam suppressed -- Suppression state

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//config/enumeration_values/:enum_val_id/suppressed"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//config/enumeration_values/:enum_val_id/suppressed"
  

```


## POST /config/enumerations 

__Description__

Create an enumeration

__Parameters__


	JSONModel(:enumeration) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//config/enumerations"
  

```


## GET /config/enumerations 

__Description__

List all defined enumerations

__Parameters__


__Returns__

	200 -- [(:enumeration)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/config/enumerations"
  

```


## POST /config/enumerations/:enum_id 

__Description__

Update an enumeration

__Parameters__


	Integer enum_id -- The ID of the enumeration to update

	JSONModel(:enumeration) <request body> -- The enumeration to update

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//config/enumerations/:enum_id"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//config/enumerations/:enum_id"
  

```


## GET /config/enumerations/:enum_id 

__Description__

Get an Enumeration

__Parameters__


	Integer enum_id -- The ID of the enumeration to retrieve

__Returns__

	200 -- (:enumeration)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/config/enumerations/:enum_id"
  

```


## POST /config/enumerations/migration 

__Description__

Migrate all records from using one value to another

__Parameters__


	JSONModel(:enumeration_migration) <request body> -- The migration request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//config/enumerations/migration"
  

```


## GET /container_profiles 

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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/container_profiles?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/container_profiles?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/container_profiles?all_ids=true"
  

```


## POST /container_profiles 

__Description__

Create a Container_Profile

__Parameters__


	JSONModel(:container_profile) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"SVFDL",
"url":"DDP324793",
"dimension_units":"feet",
"extent_dimension":"width",
"depth":"11",
"height":"20",
"width":"84"}' \
  "http://localhost:8089//container_profiles"
  

```


## DELETE /container_profiles/:id 

__Description__

Delete an Container Profile

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//container_profiles/1"

```


## GET /container_profiles/:id 

__Description__

Get a Container Profile by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:container_profile)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/container_profiles/1"
  

```


## POST /container_profiles/:id 

__Description__

Update a Container Profile

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:container_profile) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"SVFDL",
"url":"DDP324793",
"dimension_units":"feet",
"extent_dimension":"width",
"depth":"11",
"height":"20",
"width":"84"}' \
  "http://localhost:8089//container_profiles/1"
  

```


## GET /current_global_preferences 

__Description__

Get the global Preferences records for the current user.

__Parameters__


__Returns__

	200 -- {(:preference)}


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/current_global_preferences"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/delete-feed?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/delete-feed?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/delete-feed?all_ids=true"
  

```


## GET /extent_calculator 

__Description__

Calculate the extent of an archival object tree

__Parameters__


	String record_uri -- The uri of the object

	String unit -- The unit of measurement to use

__Returns__

	200 -- Calculation results


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/extent_calculator"
  

```


## GET /location_profiles 

__Description__

Get a list of Location Profiles

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

	200 -- [(:location_profile)]


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/location_profiles?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/location_profiles?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/location_profiles?all_ids=true"
  

```


## POST /location_profiles 

__Description__

Create a Location_Profile

__Parameters__


	JSONModel(:location_profile) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"544GGWJ",
"dimension_units":"inches",
"depth":"36",
"height":"94",
"width":"36"}' \
  "http://localhost:8089//location_profiles"
  

```


## GET /location_profiles/:id 

__Description__

Get a Location Profile by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:location_profile)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/location_profiles/1"
  

```


## DELETE /location_profiles/:id 

__Description__

Delete an Location Profile

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//location_profiles/1"

```


## POST /location_profiles/:id 

__Description__

Update a Location Profile

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:location_profile) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"544GGWJ",
"dimension_units":"inches",
"depth":"36",
"height":"94",
"width":"36"}' \
  "http://localhost:8089//location_profiles/1"
  

```


## POST /locations 

__Description__

Create a Location

__Parameters__


	JSONModel(:location) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location",
"external_ids":[],
"functions":[],
"building":"192 W 7th Street",
"floor":"12",
"room":"9",
"area":"Front",
"barcode":"11010010010000000000",
"temporary":"reading_room"}' \
  "http://localhost:8089//locations"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/locations?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/locations?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/locations?all_ids=true"
  

```


## POST /locations/:id 

__Description__

Update a Location

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:location) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location",
"external_ids":[],
"functions":[],
"building":"192 W 7th Street",
"floor":"12",
"room":"9",
"area":"Front",
"barcode":"11010010010000000000",
"temporary":"reading_room"}' \
  "http://localhost:8089//locations/1"
  

```


## DELETE /locations/:id 

__Description__

Delete a Location

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//locations/1"

```


## GET /locations/:id 

__Description__

Get a Location by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:location)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/locations/1"
  

```


## POST /locations/batch 

__Description__

Create a Batch of Locations

__Parameters__


	RESTHelpers::BooleanParam dry_run -- If true, don't create the locations, just list them

	JSONModel(:location_batch) <request body> -- The location batch data to generate all locations

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//locations/batch"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//locations/batch"
  

```


## POST /locations/batch_update 

__Description__

Update a Location

__Parameters__


	JSONModel(:location_batch_update) <request body> -- The location batch data to update all locations

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//locations/batch_update"
  

```


## POST /logout 

__Description__

Log out the current session

__Parameters__


__Returns__

	200 -- Session logged out


```shell 
  

```


## POST /merge_requests/agent 

__Description__

Carry out a merge request against Agent records

__Parameters__


	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//merge_requests/agent"
  

```


## POST /merge_requests/digital_object 

__Description__

Carry out a merge request against Digital_Object records

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//merge_requests/digital_object"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//merge_requests/digital_object"
  

```


## POST /merge_requests/resource 

__Description__

Carry out a merge request against Resource records

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//merge_requests/resource"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//merge_requests/resource"
  

```


## POST /merge_requests/subject 

__Description__

Carry out a merge request against Subject records

__Parameters__


	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//merge_requests/subject"
  

```


## GET /notifications 

__Description__

Get a stream of notifications

__Parameters__


	Integer last_sequence -- The last sequence number seen

__Returns__

	200 -- a list of notifications


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/notifications"
  

```


## GET /permissions 

__Description__

Get a list of Permissions

__Parameters__


	String level -- The permission level to get (one of: repository, global, all) -- Must be one of repository, global, all

__Returns__

	200 -- [(:permission)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/permissions"
  

```


## GET /reports 

__Description__

List all reports

__Parameters__


__Returns__

	200 -- report list in json


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/reports"
  

```


## GET /reports/static/* 

__Description__

Get a static asset for a report

__Parameters__


	String splat -- The requested asset

__Returns__

	200 -- the asset


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/reports/static/*"
  

```


## GET /repositories 

__Description__

Get a list of Repositories

__Parameters__


__Returns__

	200 -- [(:repository)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories"
  

```


## POST /repositories 

__Description__

Create a Repository

__Parameters__


	JSONModel(:repository) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	403 -- access_denied


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories"
  

```


## GET /repositories/:id 

__Description__

Get a Repository by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:repository)
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/1"
  

```


## POST /repositories/:id 

__Description__

Update a repository

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:repository) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/1"
  

```


## DELETE /repositories/:repo_id 

__Description__

Delete a Repository

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id"

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/accessions?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/accessions?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/accessions?all_ids=true"
  

```


## POST /repositories/:repo_id/accessions 

__Description__

Create an Accession

__Parameters__


	JSONModel(:accession) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"accession",
"external_ids":[],
"related_accessions":[],
"classifications":[],
"subjects":[],
"linked_events":[],
"extents":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"deaccessions":[],
"related_resources":[],
"restrictions_apply":false,
"access_restrictions":false,
"use_restrictions":false,
"linked_agents":[],
"instances":[],
"id_0":"A852YJN",
"id_1":"L961564165709",
"id_2":"676352GMB",
"id_3":"O205NI193",
"title":"Accession Title: 353",
"content_description":"Description: 260",
"condition_description":"Description: 261",
"accession_date":"2013-05-01"}' \
  "http://localhost:8089//repositories/:repo_id/accessions"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions"
  

```


## DELETE /repositories/:repo_id/accessions/:id 

__Description__

Delete an Accession

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/accessions/1"

```


## GET /repositories/:repo_id/accessions/:id 

__Description__

Get an Accession by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:accession)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/accessions/1"
  

```


## POST /repositories/:repo_id/accessions/:id 

__Description__

Update an Accession

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:accession) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"accession",
"external_ids":[],
"related_accessions":[],
"classifications":[],
"subjects":[],
"linked_events":[],
"extents":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"deaccessions":[],
"related_resources":[],
"restrictions_apply":false,
"access_restrictions":false,
"use_restrictions":false,
"linked_agents":[],
"instances":[],
"id_0":"A852YJN",
"id_1":"L961564165709",
"id_2":"676352GMB",
"id_3":"O205NI193",
"title":"Accession Title: 353",
"content_description":"Description: 260",
"condition_description":"Description: 261",
"accession_date":"2013-05-01"}' \
  "http://localhost:8089//repositories/:repo_id/accessions/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1"
  

```


## POST /repositories/:repo_id/accessions/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1/suppressed"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1/suppressed"
  

```


## POST /repositories/:repo_id/accessions/:id/transfer 

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"LY215Q313"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1/transfer"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1/transfer"
  

```


## GET /repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a corporate entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_contexts/corporate_entities/1.:fmt/metadata"
  

```


## GET /repositories/:repo_id/archival_contexts/corporate_entities/:id.xml 

__Description__

Get an EAC-CPF representation of a Corporate Entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_contexts/corporate_entities/1.xml"
  

```


## GET /repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_contexts/families/1.:fmt/metadata"
  

```


## GET /repositories/:repo_id/archival_contexts/families/:id.xml 

__Description__

Get an EAC-CPF representation of a Family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_contexts/families/1.xml"
  

```


## GET /repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a person

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_contexts/people/1.:fmt/metadata"
  

```


## GET /repositories/:repo_id/archival_contexts/people/:id.xml 

__Description__

Get an EAC-CPF representation of an Agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_contexts/people/1.xml"
  

```


## GET /repositories/:repo_id/archival_contexts/softwares/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a software

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_contexts/softwares/1.:fmt/metadata"
  

```


## GET /repositories/:repo_id/archival_contexts/softwares/:id.xml 

__Description__

Get an EAC-CPF representation of a Software agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_contexts/softwares/1.xml"
  

```


## POST /repositories/:repo_id/archival_objects 

__Description__

Create an Archival Object

__Parameters__


	JSONModel(:archival_object) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"archival_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions_apply":false,
"instances":[],
"notes":[],
"ref_id":"OTS180671",
"level":"item",
"title":"Archival Object Title: 354"}' \
  "http://localhost:8089//repositories/:repo_id/archival_objects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_objects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_objects?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_objects?all_ids=true"
  

```


## DELETE /repositories/:repo_id/archival_objects/:id 

__Description__

Delete an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/archival_objects/1"

```


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


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_objects/1"
  

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"archival_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions_apply":false,
"instances":[],
"notes":[],
"ref_id":"OTS180671",
"level":"item",
"title":"Archival Object Title: 354"}' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"N806725PT"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/accept_children"
  

```


## GET /repositories/:repo_id/archival_objects/:id/children 

__Description__

Get the children of an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of archival object references
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/archival_objects/1/children"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/children"
  

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/parent"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/parent"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/parent"
  

```


## POST /repositories/:repo_id/archival_objects/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/suppressed"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/suppressed"
  

```


## POST /repositories/:repo_id/batch_imports 

__Description__

Import a batch of records

__Parameters__


	body_stream batch_import -- The batch of records

	Integer repo_id -- The Repository ID -- The Repository must exist

	String migration -- Param to indicate we are using a migrator

	RESTHelpers::BooleanParam skip_results -- If true, don't return the list of created record URIs

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"body_stream"' \
  "http://localhost:8089//repositories/:repo_id/batch_imports"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/batch_imports"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"NT196A915"' \
  "http://localhost:8089//repositories/:repo_id/batch_imports"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/batch_imports"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classification_terms?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classification_terms?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classification_terms?all_ids=true"
  

```


## POST /repositories/:repo_id/classification_terms 

__Description__

Create a Classification Term

__Parameters__


	JSONModel(:classification_term) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/classification_terms"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms"
  

```


## DELETE /repositories/:repo_id/classification_terms/:id 

__Description__

Delete a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/classification_terms/1"

```


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


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classification_terms/1"
  

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"SG576233U"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/accept_children"
  

```


## GET /repositories/:repo_id/classification_terms/:id/children 

__Description__

Get the children of a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of classification term references
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classification_terms/1/children"
  

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/parent"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/parent"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/parent"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classifications?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classifications?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classifications?all_ids=true"
  

```


## POST /repositories/:repo_id/classifications 

__Description__

Create a Classification

__Parameters__


	JSONModel(:classification) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification",
"publish":true,
"path_from_root":[],
"linked_records":[],
"identifier":"DP351NG",
"title":"Classification Title: 355",
"description":"Description: 262"}' \
  "http://localhost:8089//repositories/:repo_id/classifications"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications"
  

```


## DELETE /repositories/:repo_id/classifications/:id 

__Description__

Delete a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/classifications/1"

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification",
"publish":true,
"path_from_root":[],
"linked_records":[],
"identifier":"DP351NG",
"title":"Classification Title: 355",
"description":"Description: 262"}' \
  "http://localhost:8089//repositories/:repo_id/classifications/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1"
  

```


## GET /repositories/:repo_id/classifications/:id 

__Description__

Get a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:classification)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classifications/1"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"NQNEW"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/accept_children"
  

```


## GET /repositories/:repo_id/classifications/:id/tree 

__Description__

Get a Classification tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/classifications/1/tree"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"N457FEH"' \
  "http://localhost:8089//repositories/:repo_id/component_transfers"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"633LXBI"' \
  "http://localhost:8089//repositories/:repo_id/component_transfers"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/component_transfers"
  

```


## GET /repositories/:repo_id/current_preferences 

__Description__

Get the Preferences records for the current repository and user.

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {(:preference)}


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/current_preferences"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/default_values/:record_type"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/default_values/:record_type"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"364TUPW"' \
  "http://localhost:8089//repositories/:repo_id/default_values/:record_type"
  

```


## GET /repositories/:repo_id/default_values/:record_type 

__Description__

Get default values for a record type

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/default_values/:record_type"
  

```


## POST /repositories/:repo_id/digital_object_components 

__Description__

Create an Digital Object Component

__Parameters__


	JSONModel(:digital_object_component) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object_component",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[],
"notes":[],
"component_id":"R796XM133",
"title":"Digital Object Component Title: 358"}' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_object_components?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_object_components?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_object_components?all_ids=true"
  

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object_component",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[],
"notes":[],
"component_id":"R796XM133",
"title":"Digital Object Component Title: 358"}' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1"
  

```


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


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_object_components/1"
  

```


## DELETE /repositories/:repo_id/digital_object_components/:id 

__Description__

Delete a Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/digital_object_components/1"

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"O914WM760"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/accept_children"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/children"
  

```


## GET /repositories/:repo_id/digital_object_components/:id/children 

__Description__

Get the children of an Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object_component)]
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_object_components/1/children"
  

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/parent"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/parent"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/parent"
  

```


## POST /repositories/:repo_id/digital_object_components/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/suppressed"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/suppressed"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects?all_ids=true"
  

```


## POST /repositories/:repo_id/digital_objects 

__Description__

Create a Digital Object

__Parameters__


	JSONModel(:digital_object) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"part",
"number":"91",
"extent_type":"reels"}],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"317BEVE",
"use_statement":"audio-clip",
"xlink_actuate_attribute":"none",
"xlink_show_attribute":"embed",
"file_format_name":"pdf",
"file_format_version":"882UA214490",
"file_size_bytes":49,
"checksum":"973LTAD",
"checksum_method":"sha-256"}],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 357",
"language":"aym",
"digital_object_id":"G783FLC"}' \
  "http://localhost:8089//repositories/:repo_id/digital_objects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects"
  

```


## DELETE /repositories/:repo_id/digital_objects/:id 

__Description__

Delete a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/digital_objects/1"

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"part",
"number":"91",
"extent_type":"reels"}],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"317BEVE",
"use_statement":"audio-clip",
"xlink_actuate_attribute":"none",
"xlink_show_attribute":"embed",
"file_format_name":"pdf",
"file_format_version":"882UA214490",
"file_size_bytes":49,
"checksum":"973LTAD",
"checksum_method":"sha-256"}],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 357",
"language":"aym",
"digital_object_id":"G783FLC"}' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1"
  

```


## GET /repositories/:repo_id/digital_objects/:id 

__Description__

Get a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:digital_object)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects/1"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"J483815123490"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/accept_children"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/children"
  

```


## POST /repositories/:repo_id/digital_objects/:id/publish 

__Description__

Publish a digital object and all its sub-records and components

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/publish"
  

```


## POST /repositories/:repo_id/digital_objects/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/suppressed"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/suppressed"
  

```


## POST /repositories/:repo_id/digital_objects/:id/transfer 

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"UJ183SQ"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/transfer"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/transfer"
  

```


## GET /repositories/:repo_id/digital_objects/:id/tree 

__Description__

Get a Digital Object tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects/1/tree"
  

```


## GET /repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata 

__Description__

Get metadata for a Dublin Core export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects/dublin_core/1.:fmt/metadata"
  

```


## GET /repositories/:repo_id/digital_objects/dublin_core/:id.xml 

__Description__

Get a Dublin Core representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects/dublin_core/1.xml"
  

```


## GET /repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata 

__Description__

Get metadata for a METS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects/mets/1.:fmt/metadata"
  

```


## GET /repositories/:repo_id/digital_objects/mets/:id.xml 

__Description__

Get a METS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects/mets/1.xml"
  

```


## GET /repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata 

__Description__

Get metadata for a MODS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects/mods/1.:fmt/metadata"
  

```


## GET /repositories/:repo_id/digital_objects/mods/:id.xml 

__Description__

Get a MODS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/digital_objects/mods/1.xml"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/events?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/events?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/events?all_ids=true"
  

```


## POST /repositories/:repo_id/events 

__Description__

Create an Event

__Parameters__


	JSONModel(:event) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"event",
"external_ids":[],
"external_documents":[],
"linked_agents":[{ "ref":"/agents/people/271",
"role":"recipient"}],
"linked_records":[{ "ref":"/repositories/2/accessions/97",
"role":"transfer"}],
"date":{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1972-10-09",
"end":"1972-10-09",
"expression":"A861955VW"},
"event_type":"accumulation"}' \
  "http://localhost:8089//repositories/:repo_id/events"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/events"
  

```


## DELETE /repositories/:repo_id/events/:id 

__Description__

Delete an event record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/events/1"

```


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


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/events/1"
  

```


## POST /repositories/:repo_id/events/:id 

__Description__

Update an Event

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:event) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"event",
"external_ids":[],
"external_documents":[],
"linked_agents":[{ "ref":"/agents/people/271",
"role":"recipient"}],
"linked_records":[{ "ref":"/repositories/2/accessions/97",
"role":"transfer"}],
"date":{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1972-10-09",
"end":"1972-10-09",
"expression":"A861955VW"},
"event_type":"accumulation"}' \
  "http://localhost:8089//repositories/:repo_id/events/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/events/1"
  

```


## POST /repositories/:repo_id/events/:id/suppressed 

__Description__

Suppress this record from non-managers

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/events/1/suppressed"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/events/1/suppressed"
  

```


## GET /repositories/:repo_id/find_by_id/archival_objects 

__Description__

Find Archival Objects by ref_id or component_id

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] ref_id -- A set of record Ref IDs

	[String] component_id -- A set of record component IDs

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- JSON array of refs


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/find_by_id/archival_objects"
  

```


## GET /repositories/:repo_id/find_by_id/digital_object_components 

__Description__

Find Digital Object Components by component_id

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] component_id -- A set of record component IDs

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- JSON array of refs


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/find_by_id/digital_object_components"
  

```


## GET /repositories/:repo_id/groups 

__Description__

Get a list of groups for a repository

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String group_code -- Get groups by group code

__Returns__

	200 -- [(:resource)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/groups"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 267",
"member_usernames":[],
"grants_permissions":[],
"group_code":"286NLKP"}' \
  "http://localhost:8089//repositories/:repo_id/groups"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/groups"
  

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 267",
"member_usernames":[],
"grants_permissions":[],
"group_code":"286NLKP"}' \
  "http://localhost:8089//repositories/:repo_id/groups/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/groups/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/groups/1"
  

```


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


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/groups/1"
  

```


## DELETE /repositories/:repo_id/groups/:id 

__Description__

Delete a group by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:group)
	404 -- Not found


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/groups/1"

```


## POST /repositories/:repo_id/jobs 

__Description__

Create a new import job

__Parameters__


	JSONModel(:job) <request body> -- The job object

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"job",
"status":"queued",
"job_type":"import_job"}' \
  "http://localhost:8089//repositories/:repo_id/jobs"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs?all_ids=true"
  

```


## GET /repositories/:repo_id/jobs/:id 

__Description__

Get a Job by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:job)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/1"
  

```


## POST /repositories/:repo_id/jobs/:id/cancel 

__Description__

Cancel a job

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1/cancel"
  

```


## GET /repositories/:repo_id/jobs/:id/log 

__Description__

Get a Job's log by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::NonNegativeInteger offset -- The byte offset of the log file to show

__Returns__

	200 -- The section of the import log between 'offset' and the end of file


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/1/log"
  

```


## GET /repositories/:repo_id/jobs/:id/output_files 

__Description__

Get a list of Job's output files by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- An array of output files


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/1/output_files"
  

```


## GET /repositories/:repo_id/jobs/:id/output_files/:file_id 

__Description__

Get a Job's output file by ID

__Parameters__


	Integer id -- The ID of the record

	Integer file_id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- Returns the file


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/1/output_files/:file_id"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/1/records?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/1/records?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/1/records?all_ids=true"
  

```


## GET /repositories/:repo_id/jobs/active 

__Description__

Get a list of all active Jobs for a Repository

__Parameters__


	[String] resolve -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:job)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/active"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/archived?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/archived?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/archived?all_ids=true"
  

```


## GET /repositories/:repo_id/jobs/import_types 

__Description__

List all supported import job types

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- A list of supported import types


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/import_types"
  

```


## GET /repositories/:repo_id/jobs/types 

__Description__

List all supported import job types

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- A list of supported job types


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/jobs/types"
  

```


## POST /repositories/:repo_id/jobs_with_files 

__Description__

Create a new import job and post input files

__Parameters__


	JSONModel(:job) job -- 

	[RESTHelpers::UploadFile] files -- 

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"job",
"status":"queued",
"job_type":"import_job"}' \
  "http://localhost:8089//repositories/:repo_id/jobs_with_files"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"UploadFile"' \
  "http://localhost:8089//repositories/:repo_id/jobs_with_files"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs_with_files"
  

```


## GET /repositories/:repo_id/preferences 

__Description__

Get a list of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer user_id -- The username to retrieve defaults for

__Returns__

	200 -- [(:preference)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/preferences"
  

```


## POST /repositories/:repo_id/preferences 

__Description__

Create a Preferences record

__Parameters__


	JSONModel(:preference) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"preference",
"defaults":{ "jsonmodel_type":"defaults",
"default_values":false,
"note_order":[],
"show_suppressed":false,
"publish":false}}' \
  "http://localhost:8089//repositories/:repo_id/preferences"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/preferences"
  

```


## GET /repositories/:repo_id/preferences/:id 

__Description__

Get a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:preference)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/preferences/1"
  

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"preference",
"defaults":{ "jsonmodel_type":"defaults",
"default_values":false,
"note_order":[],
"show_suppressed":false,
"publish":false}}' \
  "http://localhost:8089//repositories/:repo_id/preferences/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/preferences/1"
  

```


## DELETE /repositories/:repo_id/preferences/:id 

__Description__

Delete a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/preferences/1"

```


## GET /repositories/:repo_id/preferences/defaults 

__Description__

Get the default set of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String username -- The username to retrieve defaults for

__Returns__

	200 -- (defaults)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/preferences/defaults"
  

```


## GET /repositories/:repo_id/rde_templates 

__Description__

Get a list of RDE Templates

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:rde_template)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/rde_templates"
  

```


## POST /repositories/:repo_id/rde_templates 

__Description__

Create an RDE template

__Parameters__


	JSONModel(:rde_template) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/rde_templates"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/rde_templates"
  

```


## GET /repositories/:repo_id/rde_templates/:id 

__Description__

Get an RDE template record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:rde_template)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/rde_templates/1"
  

```


## DELETE /repositories/:repo_id/rde_templates/:id 

__Description__

Delete an RDE Template

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/rde_templates/1"

```


## GET /repositories/:repo_id/resource_descriptions/:id.:fmt/metadata 

__Description__

Get export metadata for a Resource Description

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	String fmt -- Format of the request

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resource_descriptions/1.:fmt/metadata"
  

```


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


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resource_descriptions/1.pdf"
  

```


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


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resource_descriptions/1.xml"
  

```


## GET /repositories/:repo_id/resource_labels/:id.:fmt/metadata 

__Description__

Get export metadata for Resource labels

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resource_labels/1.:fmt/metadata"
  

```


## GET /repositories/:repo_id/resource_labels/:id.tsv 

__Description__

Get a tsv list of printable labels for a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resource_labels/1.tsv"
  

```


## POST /repositories/:repo_id/resources 

__Description__

Create a Resource

__Parameters__


	JSONModel(:resource) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"resource",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"whole",
"number":"52",
"extent_type":"photographic_slides"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1971-12-27",
"end":"1971-12-27",
"expression":"EKH852A"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"B465QMH",
"description":"KW695NG"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"microform",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"frame",
"indicator_1":"37-577",
"barcode_1":"11110010000001000100",
"container_extent":"38",
"container_extent_type":"cubic_feet"}},
{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"moving_images",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"folder",
"indicator_1":"77-780",
"barcode_1":"11100111110101100011",
"container_extent":"7",
"container_extent_type":"terabytes"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>95</emph>",
"id_0":"751445PG125",
"level":"recordgrp",
"language":"sad",
"ead_id":"AJCVI",
"finding_aid_date":"I918316RB",
"finding_aid_language":"3782428LU",
"ead_location":"IN145HW"}' \
  "http://localhost:8089//repositories/:repo_id/resources"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resources?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resources?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resources?all_ids=true"
  

```


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


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"resource",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"whole",
"number":"52",
"extent_type":"photographic_slides"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1971-12-27",
"end":"1971-12-27",
"expression":"EKH852A"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"B465QMH",
"description":"KW695NG"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"microform",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"frame",
"indicator_1":"37-577",
"barcode_1":"11110010000001000100",
"container_extent":"38",
"container_extent_type":"cubic_feet"}},
{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"moving_images",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"folder",
"indicator_1":"77-780",
"barcode_1":"11100111110101100011",
"container_extent":"7",
"container_extent_type":"terabytes"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>95</emph>",
"id_0":"751445PG125",
"level":"recordgrp",
"language":"sad",
"ead_id":"AJCVI",
"finding_aid_date":"I918316RB",
"finding_aid_language":"3782428LU",
"ead_location":"IN145HW"}' \
  "http://localhost:8089//repositories/:repo_id/resources/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1"
  

```


## GET /repositories/:repo_id/resources/:id 

__Description__

Get a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:resource)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resources/1"
  

```


## DELETE /repositories/:repo_id/resources/:id 

__Description__

Delete a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/resources/1"

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"EOJ842356"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/accept_children"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/resources/1/children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/children"
  

```


## GET /repositories/:repo_id/resources/:id/models_in_graph 

__Description__

Get a list of record types in the graph of a resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resources/1/models_in_graph"
  

```


## POST /repositories/:repo_id/resources/:id/publish 

__Description__

Publish a resource and all its sub-records and components

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/publish"
  

```


## POST /repositories/:repo_id/resources/:id/suppressed 

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/suppressed"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/suppressed"
  

```


## POST /repositories/:repo_id/resources/:id/transfer 

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"X209M859M"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/transfer"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/transfer"
  

```


## GET /repositories/:repo_id/resources/:id/tree 

__Description__

Get a Resource tree

__Parameters__


	Integer id -- The ID of the record

	String limit_to -- An Archival Object URI or 'root'

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resources/1/tree"
  

```


## GET /repositories/:repo_id/resources/marc21/:id.:fmt/metadata 

__Description__

Get metadata for a MARC21 export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resources/marc21/1.:fmt/metadata"
  

```


## GET /repositories/:repo_id/resources/marc21/:id.xml 

__Description__

Get a MARC 21 representation of a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/resources/marc21/1.xml"
  

```


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

	String q -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/search?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/search?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/search?all_ids=true"
  

```


## GET /repositories/:repo_id/top_containers 

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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/top_containers?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/top_containers?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/top_containers?all_ids=true"
  

```


## POST /repositories/:repo_id/top_containers 

__Description__

Create a top container

__Parameters__


	JSONModel(:top_container) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"top_container",
"active_restrictions":[],
"container_locations":[],
"series":[],
"collection":[],
"indicator":"OTUY708",
"type":"folder",
"barcode":"TYRL6",
"ils_holding_id":"XEJ964F",
"ils_item_id":"LFC532V",
"exported_to_ils":"2017-02-15T10:04:26-05:00"}' \
  "http://localhost:8089//repositories/:repo_id/top_containers"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers"
  

```


## POST /repositories/:repo_id/top_containers/:id 

__Description__

Update a top container

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:top_container) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"top_container",
"active_restrictions":[],
"container_locations":[],
"series":[],
"collection":[],
"indicator":"OTUY708",
"type":"folder",
"barcode":"TYRL6",
"ils_holding_id":"XEJ964F",
"ils_item_id":"LFC532V",
"exported_to_ils":"2017-02-15T10:04:26-05:00"}' \
  "http://localhost:8089//repositories/:repo_id/top_containers/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/1"
  

```


## GET /repositories/:repo_id/top_containers/:id 

__Description__

Get a top container by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:top_container)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/top_containers/1"
  

```


## DELETE /repositories/:repo_id/top_containers/:id 

__Description__

Delete a top container

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//repositories/:repo_id/top_containers/1"

```


## POST /repositories/:repo_id/top_containers/batch/container_profile 

__Description__

Update container profile for a batch of top containers

__Parameters__


	[Integer] ids -- 

	String container_profile_uri -- The uri of the container profile

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/container_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"611F12UJ"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/container_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/container_profile"
  

```


## POST /repositories/:repo_id/top_containers/batch/ils_holding_id 

__Description__

Update ils_holding_id for a batch of top containers

__Parameters__


	[Integer] ids -- 

	String ils_holding_id -- Value to set for ils_holding_id

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/ils_holding_id"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"SQ337E840"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/ils_holding_id"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/ils_holding_id"
  

```


## POST /repositories/:repo_id/top_containers/batch/location 

__Description__

Update location for a batch of top containers

__Parameters__


	[Integer] ids -- 

	String location_uri -- The uri of the location

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/location"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"749V408FK"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/location"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/location"
  

```


## POST /repositories/:repo_id/top_containers/bulk/barcodes 

__Description__

Bulk update barcodes

__Parameters__


	String <request body> -- JSON string containing barcode data {uri=>barcode}

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"496416MYQ"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/barcodes"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/barcodes"
  

```


## POST /repositories/:repo_id/top_containers/bulk/locations 

__Description__

Bulk update locations

__Parameters__


	String <request body> -- JSON string containing location data {container_uri=>location_uri}

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"519IM823347"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/locations"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/locations"
  

```


## GET /repositories/:repo_id/top_containers/search 

__Description__

Search for top containers

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String q -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- [(:top_container)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/top_containers/search"
  

```


## POST /repositories/:repo_id/transfer 

__Description__

Transfer this record to a different repository

__Parameters__


	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"839698G130619"' \
  "http://localhost:8089//repositories/:repo_id/transfer"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/transfer"
  

```


## GET /repositories/:repo_id/users/:id 

__Description__

Get a user's details including their groups for the current repository

__Parameters__


	Integer id -- The username id to fetch

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:user)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id/users/1"
  

```


## POST /repositories/with_agent 

__Description__

Create a Repository with an agent representation

__Parameters__


	JSONModel(:repository_with_agent) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	403 -- access_denied


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/with_agent"
  

```


## GET /repositories/with_agent/:id 

__Description__

Get a Repository by ID, including its agent representation

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:repository_with_agent)
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/with_agent/1"
  

```


## POST /repositories/with_agent/:id 

__Description__

Update a repository with an agent representation

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:repository_with_agent) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/with_agent/1"
  

```


## GET /schemas 

__Description__

Get all ArchivesSpace schemas

__Parameters__


__Returns__

	200 -- ArchivesSpace (schemas)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/schemas"
  

```


## GET /schemas/:schema 

__Description__

Get an ArchivesSpace schema

__Parameters__


	String schema -- Schema name to retrieve

__Returns__

	200 -- ArchivesSpace (:schema)
	404 -- Schema not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/schemas/:schema"
  

```


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

	String q -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search?all_ids=true"
  

```


## GET /search/location_profile 

__Description__

Search across Location Profiles

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

	String q -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/location_profile?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/location_profile?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/location_profile?all_ids=true"
  

```


## GET /search/published_tree 

__Description__

Find the tree view for a particular archival record

__Parameters__


	String node_uri -- The URI of the archival record to find the tree view for

__Returns__

	200 -- OK
	404 -- Not found


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/published_tree"
  

```


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

	String q -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/repositories?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/repositories?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/repositories?all_ids=true"
  

```


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

	String q -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	[String] filter_term -- A json string containing the term/value pairs to be applied as filters.  Of the form: {"fieldname": "fieldvalue"}.

	[String] simple_filter -- A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/subjects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/subjects?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/subjects?all_ids=true"
  

```


## GET /space_calculator/buildings 

__Description__

Get a Location by ID

__Parameters__


__Returns__

	200 -- Location building data as JSON


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/space_calculator/buildings"
  

```


## GET /space_calculator/by_building 

__Description__

Calculate how many containers will fit in locations for a given building

__Parameters__


	String container_profile_uri -- The uri of the container profile

	String building -- The building to check for space in

	String floor -- The floor to check for space in

	String room -- The room to check for space in

	String area -- The area to check for space in

__Returns__

	200 -- Calculation results


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/space_calculator/by_building"
  

```


## GET /space_calculator/by_location 

__Description__

Calculate how many containers will fit in a list of locations

__Parameters__


	String container_profile_uri -- The uri of the container profile

	[String] location_uris -- A list of location uris to calculate space for

__Returns__

	200 -- Calculation results


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/space_calculator/by_location"
  

```


## POST /subjects 

__Description__

Create a Subject

__Parameters__


	JSONModel(:subject) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"subject",
"external_ids":[],
"publish":true,
"terms":[{ "jsonmodel_type":"term",
"term":"Term 132",
"term_type":"cultural_context",
"vocabulary":"/vocabularies/156"}],
"external_documents":[],
"vocabulary":"/vocabularies/157",
"authority_id":"http://www.example-476.com",
"scope_note":"400L68798109",
"source":"aat"}' \
  "http://localhost:8089//subjects"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/subjects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/subjects?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/subjects?all_ids=true"
  

```


## GET /subjects/:id 

__Description__

Get a Subject by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:subject)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/subjects/1"
  

```


## POST /subjects/:id 

__Description__

Update a Subject

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:subject) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"subject",
"external_ids":[],
"publish":true,
"terms":[{ "jsonmodel_type":"term",
"term":"Term 132",
"term_type":"cultural_context",
"vocabulary":"/vocabularies/156"}],
"external_documents":[],
"vocabulary":"/vocabularies/157",
"authority_id":"http://www.example-476.com",
"scope_note":"400L68798109",
"source":"aat"}' \
  "http://localhost:8089//subjects/1"
  

```


## DELETE /subjects/:id 

__Description__

Delete a Subject

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//subjects/1"

```


## GET /terms 

__Description__

Get a list of Terms matching a prefix

__Parameters__


	String q -- The prefix to match

__Returns__

	200 -- [(:term)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/terms"
  

```


## GET /update-feed 

__Description__

Get a stream of updated records

__Parameters__


	Integer last_sequence -- The last sequence number seen

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- a list of records and sequence numbers


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/update-feed"
  

```


## POST /update_monitor 

__Description__

Refresh the list of currently known edits

__Parameters__


	JSONModel(:active_edits) <request body> -- The list of active edits

__Returns__

	200 -- A list of records, the user editing it and the lock version for each


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//update_monitor"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"U898SXE"' \
  "http://localhost:8089//users"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"ARES968"' \
  "http://localhost:8089//users"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_admin":false,
"username":"username_21",
"name":"Name Number 514"}' \
  "http://localhost:8089//users"
  

```


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


```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users?all_ids=true"
  

```


## POST /users/:id 

__Description__

Update a user's account

__Parameters__


	Integer id -- The ID of the record

	String password -- The user's password

	JSONModel(:user) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"IK342YW"' \
  "http://localhost:8089//users/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_admin":false,
"username":"username_21",
"name":"Name Number 514"}' \
  "http://localhost:8089//users/1"
  

```


## GET /users/:id 

__Description__

Get a user's details (including their current permissions)

__Parameters__


	Integer id -- The username id to fetch

__Returns__

	200 -- (:user)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users/1"
  

```


## DELETE /users/:id 

__Description__

Delete a user

__Parameters__


	Integer id -- The user to delete

__Returns__

	200 -- deleted


```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089//users/1"

```


## POST /users/:id/groups 

__Description__

Update a user's groups

__Parameters__


	Integer id -- The ID of the record

	[String] groups -- Array of groups URIs to assign the user to

	RESTHelpers::BooleanParam remove_groups -- Remove all groups from the user for the current repo_id if true

	Integer repo_id -- The Repository groups to clear

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"613G627727S"' \
  "http://localhost:8089//users/1/groups"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//users/1/groups"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//users/1/groups"
  

```


## POST /users/:username/become-user 

__Description__

Become a different user

__Parameters__


	Username username -- The username to become

__Returns__

	200 -- Accepted
	404 -- User not found


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"username_22"' \
  "http://localhost:8089//users/:username/become-user"
  

```


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


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"username_23"' \
  "http://localhost:8089//users/:username/login"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"GB555ND"' \
  "http://localhost:8089//users/:username/login"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//users/:username/login"
  

```


## GET /users/complete 

__Description__

Get a list of system users

__Parameters__


	String query -- A prefix to search for

__Returns__

	200 -- A list of usernames


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users/complete"
  

```


## GET /users/current-user 

__Description__

Get the currently logged in user

__Parameters__


__Returns__

	200 -- (:user)
	404 -- Not logged in


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users/current-user"
  

```


## GET /version 

__Description__

Get the ArchivesSpace application version

__Parameters__


__Returns__

	200 -- ArchivesSpace (version)


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/version"
  

```


## POST /vocabularies 

__Description__

Create a Vocabulary

__Parameters__


	JSONModel(:vocabulary) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//vocabularies"
  

```


## GET /vocabularies 

__Description__

Get a list of Vocabularies

__Parameters__


	String ref_id -- An alternate, externally-created ID for the vocabulary

__Returns__

	200 -- [(:vocabulary)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/vocabularies"
  

```


## POST /vocabularies/:id 

__Description__

Update a Vocabulary

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:vocabulary) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//vocabularies/1"
  

```


## GET /vocabularies/:id 

__Description__

Get a Vocabulary by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- OK


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/vocabularies/1"
  

```


## GET /vocabularies/:id/terms 

__Description__

Get a list of Terms for a Vocabulary

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- [(:term)]


```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/vocabularies/1/terms"
  

```



