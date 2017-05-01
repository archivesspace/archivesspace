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
As of 2017-05-02 08:51:54 -0400 the following REST endpoints exist in the master branch of the development repository:


## [:POST] /agents/corporate_entities 

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
"number":"703 64468 222 0375 37610"}],
"name":"Name Number 515",
"address_3":"WUG881813",
"city":"OT701XG",
"region":"638LN14174",
"country":"BLUSW",
"fax":"WO463446273",
"note":"OQX643A"}],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"used_within_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"1998-07-18",
"end":"1998-07-18",
"expression":"558MDI9"}],
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"primary_name":"Name Number 514",
"subordinate_name_1":"QRU888586",
"subordinate_name_2":"TH39T719",
"number":"P39FYO",
"sort_name":"SORT l - 429",
"dates":"171GCLD",
"qualifier":"BRE163950",
"authority_id":"http://www.example-474.com",
"source":"nad"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089//agents/corporate_entities"
  

```


## [:GET] /agents/corporate_entities 

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
  

```


## [:POST] /agents/corporate_entities/:id 

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
"number":"703 64468 222 0375 37610"}],
"name":"Name Number 515",
"address_3":"WUG881813",
"city":"OT701XG",
"region":"638LN14174",
"country":"BLUSW",
"fax":"WO463446273",
"note":"OQX643A"}],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"used_within_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"1998-07-18",
"end":"1998-07-18",
"expression":"558MDI9"}],
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"primary_name":"Name Number 514",
"subordinate_name_1":"QRU888586",
"subordinate_name_2":"TH39T719",
"number":"P39FYO",
"sort_name":"SORT l - 429",
"dates":"171GCLD",
"qualifier":"BRE163950",
"authority_id":"http://www.example-474.com",
"source":"nad"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089//agents/corporate_entities/1"
  

```


## [:GET] /agents/corporate_entities/:id 

__Description__

Get a corporate entity by ID

__Parameters__


	Integer id -- ID of the corporate entity agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent_corporate_entity)
	404 -- Not found


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"NQK890558"' \
  "http://localhost:8089//agents/corporate_entities/1"
  

```


## [:DELETE] /agents/corporate_entities/:id 

__Description__

Delete a corporate entity agent

__Parameters__


	Integer id -- ID of the corporate entity agent

__Returns__

	200 -- deleted


```shell 
    
  

```


## [:POST] /agents/families 

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
"used_within_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"existence",
"begin":"1993-07-26",
"end":"1993-07-26",
"expression":"C399203468P"}],
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"local",
"family_name":"Name Number 516",
"sort_name":"SORT l - 430",
"dates":"Y691FY89",
"qualifier":"YQKT444",
"prefix":"MNXA280",
"authority_id":"http://www.example-475.com",
"source":"naf"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089//agents/families"
  

```


## [:GET] /agents/families 

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
  

```


## [:POST] /agents/families/:id 

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
"used_within_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"existence",
"begin":"1993-07-26",
"end":"1993-07-26",
"expression":"C399203468P"}],
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"local",
"family_name":"Name Number 516",
"sort_name":"SORT l - 430",
"dates":"Y691FY89",
"qualifier":"YQKT444",
"prefix":"MNXA280",
"authority_id":"http://www.example-475.com",
"source":"naf"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089//agents/families/1"
  

```


## [:GET] /agents/families/:id 

__Description__

Get a family by ID

__Parameters__


	Integer id -- ID of the family agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"QNA355W"' \
  "http://localhost:8089//agents/families/1"
  

```


## [:DELETE] /agents/families/:id 

__Description__

Delete an agent family

__Parameters__


	Integer id -- ID of the family agent

__Returns__

	200 -- deleted


```shell 
    
  

```


## [:POST] /agents/people 

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
"used_within_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"2001-09-16",
"end":"2001-09-16",
"expression":"736S266833829"}],
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"source":"ulan",
"primary_name":"Name Number 517",
"sort_name":"SORT q - 431",
"name_order":"inverted",
"number":"B176C623485",
"dates":"V939847XR",
"qualifier":"WVS238719",
"fuller_form":"146TBID",
"title":"BN21250Y",
"suffix":"FRJXW",
"authority_id":"http://www.example-476.com"}],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089//agents/people"
  

```


## [:GET] /agents/people 

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
  

```


## [:POST] /agents/people/:id 

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
"used_within_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"2001-09-16",
"end":"2001-09-16",
"expression":"736S266833829"}],
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"source":"ulan",
"primary_name":"Name Number 517",
"sort_name":"SORT q - 431",
"name_order":"inverted",
"number":"B176C623485",
"dates":"V939847XR",
"qualifier":"WVS238719",
"fuller_form":"146TBID",
"title":"BN21250Y",
"suffix":"FRJXW",
"authority_id":"http://www.example-476.com"}],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089//agents/people/1"
  

```


## [:GET] /agents/people/:id 

__Description__

Get a person by ID

__Parameters__


	Integer id -- ID of the person agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"DHUW965"' \
  "http://localhost:8089//agents/people/1"
  

```


## [:DELETE] /agents/people/:id 

__Description__

Delete an agent person

__Parameters__


	Integer id -- ID of the person agent

__Returns__

	200 -- deleted


```shell 
    
  

```


## [:POST] /agents/software 

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
"used_within_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"2011-02-10",
"end":"2011-02-10",
"expression":"660L309555481"}],
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"software_name":"Name Number 518",
"sort_name":"SORT g - 432"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089//agents/software"
  

```


## [:GET] /agents/software 

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
  

```


## [:POST] /agents/software/:id 

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
"used_within_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"2011-02-10",
"end":"2011-02-10",
"expression":"660L309555481"}],
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"software_name":"Name Number 518",
"sort_name":"SORT g - 432"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089//agents/software/1"
  

```


## [:GET] /agents/software/:id 

__Description__

Get a software agent by ID

__Parameters__


	Integer id -- ID of the software agent

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"V96340096536"' \
  "http://localhost:8089//agents/software/1"
  

```


## [:DELETE] /agents/software/:id 

__Description__

Delete a software agent

__Parameters__


	Integer id -- ID of the software agent

__Returns__

	200 -- deleted


```shell 
    
  

```


## [:POST] /batch_delete 

__Description__

Carry out delete requests against a list of records

__Parameters__


	[String] record_uris -- A list of record uris

__Returns__

	200 -- deleted


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"V591401226492"' \
  "http://localhost:8089//batch_delete"
  

```


## [:GET] /by-external-id 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"HAGOX"' \
  "http://localhost:8089//by-external-id"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"NBKT659"' \
  "http://localhost:8089//by-external-id"
  

```


## [:GET] /config/enumeration_values/:enum_val_id 

__Description__

Get an Enumeration Value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to retrieve

__Returns__

	200 -- (:enumeration_value)


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//config/enumeration_values/:enum_val_id"
  

```


## [:POST] /config/enumeration_values/:enum_val_id 

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


## [:POST] /config/enumeration_values/:enum_val_id/position 

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


## [:POST] /config/enumeration_values/:enum_val_id/suppressed 

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


## [:GET] /config/enumerations 

__Description__

List all defined enumerations

__Parameters__


__Returns__

	200 -- [(:enumeration)]


```shell 
  

```


## [:POST] /config/enumerations 

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


## [:POST] /config/enumerations/:enum_id 

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


## [:GET] /config/enumerations/:enum_id 

__Description__

Get an Enumeration

__Parameters__


	Integer enum_id -- The ID of the enumeration to retrieve

__Returns__

	200 -- (:enumeration)


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//config/enumerations/:enum_id"
  

```


## [:POST] /config/enumerations/migration 

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


## [:POST] /container_profiles 

__Description__

Create a Container_Profile

__Parameters__


	JSONModel(:container_profile) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"876LNX532",
"url":"P448YJ904",
"dimension_units":"meters",
"extent_dimension":"height",
"depth":"84",
"height":"96",
"width":"89"}' \
  "http://localhost:8089//container_profiles"
  

```


## [:GET] /container_profiles 

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
  

```


## [:POST] /container_profiles/:id 

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
"name":"876LNX532",
"url":"P448YJ904",
"dimension_units":"meters",
"extent_dimension":"height",
"depth":"84",
"height":"96",
"width":"89"}' \
  "http://localhost:8089//container_profiles/1"
  

```


## [:GET] /container_profiles/:id 

__Description__

Get a Container Profile by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:container_profile)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"Q816NM484"' \
  "http://localhost:8089//container_profiles/1"
  

```


## [:DELETE] /container_profiles/:id 

__Description__

Delete an Container Profile

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


```shell 
    
  

```


## [:GET] /current_global_preferences 

__Description__

Get the global Preferences records for the current user.

__Parameters__


__Returns__

	200 -- {(:preference)}


```shell 
  

```


## [:GET] /delete-feed 

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
  

```


## [:GET] /extent_calculator 

__Description__

Calculate the extent of an archival object tree

__Parameters__


	String record_uri -- The uri of the object

	String unit -- The unit of measurement to use

__Returns__

	200 -- Calculation results


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"U812SG305"' \
  "http://localhost:8089//extent_calculator"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"IDNSV"' \
  "http://localhost:8089//extent_calculator"
  

```


## [:GET] /job_types 

__Description__

List all supported job types

__Parameters__


__Returns__

	200 -- A list of supported job types


```shell 
  

```


## [:POST] /location_profiles 

__Description__

Create a Location_Profile

__Parameters__


	JSONModel(:location_profile) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"943EY782L",
"dimension_units":"feet",
"depth":"77",
"height":"60",
"width":"10"}' \
  "http://localhost:8089//location_profiles"
  

```


## [:GET] /location_profiles 

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
  

```


## [:POST] /location_profiles/:id 

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
"name":"943EY782L",
"dimension_units":"feet",
"depth":"77",
"height":"60",
"width":"10"}' \
  "http://localhost:8089//location_profiles/1"
  

```


## [:GET] /location_profiles/:id 

__Description__

Get a Location Profile by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:location_profile)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"OY636649517"' \
  "http://localhost:8089//location_profiles/1"
  

```


## [:DELETE] /location_profiles/:id 

__Description__

Delete an Location Profile

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


```shell 
    
  

```


## [:POST] /locations 

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
"building":"188 E 8th Street",
"floor":"0",
"room":"9",
"area":"Front",
"barcode":"01100111110100011100",
"temporary":"reading_room"}' \
  "http://localhost:8089//locations"
  

```


## [:GET] /locations 

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
  

```


## [:POST] /locations/:id 

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
"building":"188 E 8th Street",
"floor":"0",
"room":"9",
"area":"Front",
"barcode":"01100111110100011100",
"temporary":"reading_room"}' \
  "http://localhost:8089//locations/1"
  

```


## [:GET] /locations/:id 

__Description__

Get a Location by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:location)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"958XOGR"' \
  "http://localhost:8089//locations/1"
  

```


## [:DELETE] /locations/:id 

__Description__

Delete a Location

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


```shell 
    
  

```


## [:POST] /locations/batch 

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


## [:POST] /locations/batch_update 

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


## [:POST] /logout 

__Description__

Log out the current session

__Parameters__


__Returns__

	200 -- Session logged out


```shell 
  

```


## [:POST] /merge_requests/agent 

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


## [:POST] /merge_requests/digital_object 

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


## [:POST] /merge_requests/resource 

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


## [:POST] /merge_requests/subject 

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


## [:GET] /notifications 

__Description__

Get a stream of notifications

__Parameters__


	Integer last_sequence -- The last sequence number seen

__Returns__

	200 -- a list of notifications


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//notifications"
  

```


## [:GET] /permissions 

__Description__

Get a list of Permissions

__Parameters__


	String level -- The permission level to get (one of: repository, global, all) -- Must be one of repository, global, all

__Returns__

	200 -- [(:permission)]


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"UB626482A"' \
  "http://localhost:8089//permissions"
  

```


## [:GET] /reports 

__Description__

List all reports

__Parameters__


__Returns__

	200 -- report list in json


```shell 
  

```


## [:GET] /reports/static/* 

__Description__

Get a static asset for a report

__Parameters__


	String splat -- The requested asset

__Returns__

	200 -- the asset


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"JBRRH"' \
  "http://localhost:8089//reports/static/*"
  

```


## [:POST] /repositories 

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


## [:GET] /repositories 

__Description__

Get a list of Repositories

__Parameters__


	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- [(:repository)]


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"252817BUX"' \
  "http://localhost:8089//repositories"
  

```


## [:POST] /repositories/:id 

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


## [:GET] /repositories/:id 

__Description__

Get a Repository by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:repository)
	404 -- Not found


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"KU901A310"' \
  "http://localhost:8089//repositories/1"
  

```


## [:DELETE] /repositories/:repo_id 

__Description__

Delete a Repository

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id"
  

```


## [:POST] /repositories/:repo_id/accessions 

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
"id_0":"BV360XL",
"id_1":"PHMQ108",
"id_2":"ALJOV",
"id_3":"KSPTP",
"title":"Accession Title: 361",
"content_description":"Description: 260",
"condition_description":"Description: 261",
"accession_date":"2012-10-28"}' \
  "http://localhost:8089//repositories/:repo_id/accessions"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions"
  

```


## [:GET] /repositories/:repo_id/accessions 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions"
  

```


## [:POST] /repositories/:repo_id/accessions/:id 

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
"id_0":"BV360XL",
"id_1":"PHMQ108",
"id_2":"ALJOV",
"id_3":"KSPTP",
"title":"Accession Title: 361",
"content_description":"Description: 260",
"condition_description":"Description: 261",
"accession_date":"2012-10-28"}' \
  "http://localhost:8089//repositories/:repo_id/accessions/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1"
  

```


## [:GET] /repositories/:repo_id/accessions/:id 

__Description__

Get an Accession by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:accession)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"521PLTC"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1"
  

```


## [:DELETE] /repositories/:repo_id/accessions/:id 

__Description__

Delete an Accession

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1"
  

```


## [:POST] /repositories/:repo_id/accessions/:id/suppressed 

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


## [:POST] /repositories/:repo_id/accessions/:id/transfer 

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
  -d '"VI828152409"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1/transfer"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/accessions/1/transfer"
  

```


## [:GET] /repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a corporate entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_contexts/corporate_entities/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/archival_contexts/corporate_entities/:id.xml 

__Description__

Get an EAC-CPF representation of a Corporate Entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_contexts/corporate_entities/1.xml"
  

```


## [:GET] /repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_contexts/families/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/archival_contexts/families/:id.xml 

__Description__

Get an EAC-CPF representation of a Family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_contexts/families/1.xml"
  

```


## [:GET] /repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a person

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_contexts/people/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/archival_contexts/people/:id.xml 

__Description__

Get an EAC-CPF representation of an Agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_contexts/people/1.xml"
  

```


## [:GET] /repositories/:repo_id/archival_contexts/softwares/:id.:fmt/metadata 

__Description__

Get metadata for an EAC-CPF export of a software

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_contexts/softwares/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/archival_contexts/softwares/:id.xml 

__Description__

Get an EAC-CPF representation of a Software agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_contexts/softwares/1.xml"
  

```


## [:POST] /repositories/:repo_id/archival_objects 

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
"ancestors":[],
"instances":[],
"notes":[],
"ref_id":"TNY95L",
"level":"series",
"title":"Archival Object Title: 362",
"resource":{ "ref":"/repositories/2/resources/127"}}' \
  "http://localhost:8089//repositories/:repo_id/archival_objects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects"
  

```


## [:GET] /repositories/:repo_id/archival_objects 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects"
  

```


## [:POST] /repositories/:repo_id/archival_objects/:id 

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
"ancestors":[],
"instances":[],
"notes":[],
"ref_id":"TNY95L",
"level":"series",
"title":"Archival Object Title: 362",
"resource":{ "ref":"/repositories/2/resources/127"}}' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1"
  

```


## [:GET] /repositories/:repo_id/archival_objects/:id 

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
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"973J504O834"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1"
  

```


## [:DELETE] /repositories/:repo_id/archival_objects/:id 

__Description__

Delete an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1"
  

```


## [:POST] /repositories/:repo_id/archival_objects/:id/accept_children 

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
  -d '"CVSK225"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/accept_children"
  

```


## [:GET] /repositories/:repo_id/archival_objects/:id/children 

__Description__

Get the children of an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of archival object references
	404 -- Not found


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/archival_objects/1/children"
  

```


## [:POST] /repositories/:repo_id/archival_objects/:id/children 

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


## [:POST] /repositories/:repo_id/archival_objects/:id/parent 

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


## [:POST] /repositories/:repo_id/archival_objects/:id/suppressed 

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


## [:POST] /repositories/:repo_id/batch_imports 

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
  -d '"NGXYN"' \
  "http://localhost:8089//repositories/:repo_id/batch_imports"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/batch_imports"
  

```


## [:POST] /repositories/:repo_id/classification_terms 

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
  -d '{ "jsonmodel_type":"classification_term",
"publish":true,
"path_from_root":[],
"linked_records":[],
"identifier":"285RT727B",
"title":"Classification Title: 364",
"description":"Description: 263",
"classification":{ "ref":"/repositories/2/classifications/12"}}' \
  "http://localhost:8089//repositories/:repo_id/classification_terms"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms"
  

```


## [:GET] /repositories/:repo_id/classification_terms 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms"
  

```


## [:POST] /repositories/:repo_id/classification_terms/:id 

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
  -d '{ "jsonmodel_type":"classification_term",
"publish":true,
"path_from_root":[],
"linked_records":[],
"identifier":"285RT727B",
"title":"Classification Title: 364",
"description":"Description: 263",
"classification":{ "ref":"/repositories/2/classifications/12"}}' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1"
  

```


## [:GET] /repositories/:repo_id/classification_terms/:id 

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
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"WF122893957"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1"
  

```


## [:DELETE] /repositories/:repo_id/classification_terms/:id 

__Description__

Delete a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1"
  

```


## [:POST] /repositories/:repo_id/classification_terms/:id/accept_children 

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
  -d '"QTDK639"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/accept_children"
  

```


## [:GET] /repositories/:repo_id/classification_terms/:id/children 

__Description__

Get the children of a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of classification term references
	404 -- Not found


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classification_terms/1/children"
  

```


## [:POST] /repositories/:repo_id/classification_terms/:id/parent 

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


## [:POST] /repositories/:repo_id/classifications 

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
"identifier":"648UMJH",
"title":"Classification Title: 363",
"description":"Description: 262"}' \
  "http://localhost:8089//repositories/:repo_id/classifications"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications"
  

```


## [:GET] /repositories/:repo_id/classifications 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications"
  

```


## [:GET] /repositories/:repo_id/classifications/:id 

__Description__

Get a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:classification)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"CL45CJ"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1"
  

```


## [:POST] /repositories/:repo_id/classifications/:id 

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
"identifier":"648UMJH",
"title":"Classification Title: 363",
"description":"Description: 262"}' \
  "http://localhost:8089//repositories/:repo_id/classifications/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1"
  

```


## [:DELETE] /repositories/:repo_id/classifications/:id 

__Description__

Delete a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1"
  

```


## [:POST] /repositories/:repo_id/classifications/:id/accept_children 

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
  -d '"893XHLM"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/accept_children"
  

```


## [:GET] /repositories/:repo_id/classifications/:id/tree 

__Description__

Get a Classification tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree"
  

```


## [:GET] /repositories/:repo_id/classifications/:id/tree/node 

__Description__

Fetch tree information for an Classification Term record within a tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	String node_uri -- The URI of the Classification Term record of interest

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON object describing enough information about a specific node.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint

  * position -- the logical position of this record within its subtree

  * precomputed_waypoints -- a collection of arrays (keyed on child URI) in the
    same format as returned by the '/waypoint' endpoint.  Since a fetch for a
    given node is almost always followed by a fetch of the first waypoint, using
    the information in this structure can save a backend call.


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/node"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"OWRQW"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/node"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/node"
  

```


## [:GET] /repositories/:repo_id/classifications/:id/tree/node_from_root 

__Description__

Fetch tree path from the root record to Classification Terms

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[Integer] node_ids -- The IDs of the Classification Term records of interest

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON array describing the path to a node, starting from the root of the tree.  Each path element provides:

  * node -- the URI of the node to next expand

  * offset -- the waypoint number within `node` that contains the next entry in
    the path (or the desired record, if we're at the end of the path)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/node_from_root"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/node_from_root"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/node_from_root"
  

```


## [:GET] /repositories/:repo_id/classifications/:id/tree/root 

__Description__

Fetch tree information for the top-level classification record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON object describing enough information about this tree's root record to render the rest.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/root"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/root"
  

```


## [:GET] /repositories/:repo_id/classifications/:id/tree/waypoint 

__Description__

Fetch the record slice for a given tree waypoint

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer offset -- The page of records to return

	String parent_node -- The URI of the parent of this waypoint (none for the root record)

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/waypoint"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/waypoint"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"812IN652350"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/waypoint"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/classifications/1/tree/waypoint"
  

```


## [:GET] /repositories/:repo_id/collection_management/:id 

__Description__

Get a Collection Management Record by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:collection_management)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/collection_management/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"MKGKW"' \
  "http://localhost:8089//repositories/:repo_id/collection_management/1"
  

```


## [:POST] /repositories/:repo_id/component_transfers 

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
  -d '"XIR815W"' \
  "http://localhost:8089//repositories/:repo_id/component_transfers"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"458QJEM"' \
  "http://localhost:8089//repositories/:repo_id/component_transfers"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/component_transfers"
  

```


## [:GET] /repositories/:repo_id/current_preferences 

__Description__

Get the Preferences records for the current repository and user.

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {(:preference)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/current_preferences"
  

```


## [:POST] /repositories/:repo_id/default_values/:record_type 

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
  -d '"AJ875AM"' \
  "http://localhost:8089//repositories/:repo_id/default_values/:record_type"
  

```


## [:GET] /repositories/:repo_id/default_values/:record_type 

__Description__

Get default values for a record type

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/default_values/:record_type"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"RV231QE"' \
  "http://localhost:8089//repositories/:repo_id/default_values/:record_type"
  

```


## [:POST] /repositories/:repo_id/digital_object_components 

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
"component_id":"110327HCC",
"title":"Digital Object Component Title: 367",
"digital_object":{ "ref":"/repositories/2/digital_objects/56"}}' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components"
  

```


## [:GET] /repositories/:repo_id/digital_object_components 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components"
  

```


## [:POST] /repositories/:repo_id/digital_object_components/:id 

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
"component_id":"110327HCC",
"title":"Digital Object Component Title: 367",
"digital_object":{ "ref":"/repositories/2/digital_objects/56"}}' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1"
  

```


## [:GET] /repositories/:repo_id/digital_object_components/:id 

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
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"KYQSC"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1"
  

```


## [:DELETE] /repositories/:repo_id/digital_object_components/:id 

__Description__

Delete a Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1"
  

```


## [:POST] /repositories/:repo_id/digital_object_components/:id/accept_children 

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
  -d '"WGQX756"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/accept_children"
  

```


## [:POST] /repositories/:repo_id/digital_object_components/:id/children 

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


## [:GET] /repositories/:repo_id/digital_object_components/:id/children 

__Description__

Get the children of an Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object_component)]
	404 -- Not found


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_object_components/1/children"
  

```


## [:POST] /repositories/:repo_id/digital_object_components/:id/parent 

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


## [:POST] /repositories/:repo_id/digital_object_components/:id/suppressed 

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


## [:POST] /repositories/:repo_id/digital_objects 

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
"portion":"whole",
"number":"33",
"extent_type":"cassettes"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"1987-12-20",
"end":"1987-12-20",
"expression":"GGH515W"},
{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"1979-06-15",
"end":"1979-06-15",
"expression":"E210V794551"},
{ "jsonmodel_type":"date",
"date_type":"range",
"label":"creation",
"begin":"2013-09-01",
"end":"2013-09-01",
"expression":"JLJJ528"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 366",
"language":"mak",
"digital_object_id":"XTSA62"}' \
  "http://localhost:8089//repositories/:repo_id/digital_objects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects"
  

```


## [:GET] /repositories/:repo_id/digital_objects 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects"
  

```


## [:GET] /repositories/:repo_id/digital_objects/:id 

__Description__

Get a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:digital_object)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"24M53N831"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1"
  

```


## [:POST] /repositories/:repo_id/digital_objects/:id 

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
"portion":"whole",
"number":"33",
"extent_type":"cassettes"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"1987-12-20",
"end":"1987-12-20",
"expression":"GGH515W"},
{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"1979-06-15",
"end":"1979-06-15",
"expression":"E210V794551"},
{ "jsonmodel_type":"date",
"date_type":"range",
"label":"creation",
"begin":"2013-09-01",
"end":"2013-09-01",
"expression":"JLJJ528"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 366",
"language":"mak",
"digital_object_id":"XTSA62"}' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1"
  

```


## [:DELETE] /repositories/:repo_id/digital_objects/:id 

__Description__

Delete a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1"
  

```


## [:POST] /repositories/:repo_id/digital_objects/:id/accept_children 

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
  -d '"DU613FW"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/accept_children"
  

```


## [:POST] /repositories/:repo_id/digital_objects/:id/children 

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


## [:POST] /repositories/:repo_id/digital_objects/:id/publish 

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


## [:POST] /repositories/:repo_id/digital_objects/:id/suppressed 

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


## [:POST] /repositories/:repo_id/digital_objects/:id/transfer 

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
  -d '"917351855526C"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/transfer"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/transfer"
  

```


## [:GET] /repositories/:repo_id/digital_objects/:id/tree 

__Description__

Get a Digital Object tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree"
  

```


## [:GET] /repositories/:repo_id/digital_objects/:id/tree/node 

__Description__

Fetch tree information for an Digital Object Component record within a tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	String node_uri -- The URI of the Digital Object Component record of interest

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON object describing enough information about a specific node.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint

  * position -- the logical position of this record within its subtree

  * precomputed_waypoints -- a collection of arrays (keyed on child URI) in the
    same format as returned by the '/waypoint' endpoint.  Since a fetch for a
    given node is almost always followed by a fetch of the first waypoint, using
    the information in this structure can save a backend call.


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/node"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"TRW645T"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/node"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/node"
  

```


## [:GET] /repositories/:repo_id/digital_objects/:id/tree/node_from_root 

__Description__

Fetch tree paths from the root record to Digital Object Components

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[Integer] node_ids -- The IDs of the Digital Object Component records of interest

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON array describing the path to a node, starting from the root of the tree.  Each path element provides:

  * node -- the URI of the node to next expand

  * offset -- the waypoint number within `node` that contains the next entry in
    the path (or the desired record, if we're at the end of the path)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/node_from_root"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/node_from_root"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/node_from_root"
  

```


## [:GET] /repositories/:repo_id/digital_objects/:id/tree/root 

__Description__

Fetch tree information for the top-level digital object record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON object describing enough information about this tree's root record to render the rest.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/root"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/root"
  

```


## [:GET] /repositories/:repo_id/digital_objects/:id/tree/waypoint 

__Description__

Fetch the record slice for a given tree waypoint

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer offset -- The page of records to return

	String parent_node -- The URI of the parent of this waypoint (none for the root record)

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/waypoint"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/waypoint"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"HSDB479"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/waypoint"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/1/tree/waypoint"
  

```


## [:GET] /repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata 

__Description__

Get metadata for a Dublin Core export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/dublin_core/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/digital_objects/dublin_core/:id.xml 

__Description__

Get a Dublin Core representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/dublin_core/1.xml"
  

```


## [:GET] /repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata 

__Description__

Get metadata for a METS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/mets/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/digital_objects/mets/:id.xml 

__Description__

Get a METS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/mets/1.xml"
  

```


## [:GET] /repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata 

__Description__

Get metadata for a MODS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/mods/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/digital_objects/mods/:id.xml 

__Description__

Get a MODS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/digital_objects/mods/1.xml"
  

```


## [:POST] /repositories/:repo_id/events 

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
"linked_agents":[{ "ref":"/agents/people/274",
"role":"transmitter"}],
"linked_records":[{ "ref":"/repositories/2/accessions/97",
"role":"outcome"}],
"date":{ "jsonmodel_type":"date",
"date_type":"inclusive",
"label":"creation",
"begin":"1982-06-17",
"end":"1982-06-17",
"expression":"RF493XW"},
"event_type":"processed"}' \
  "http://localhost:8089//repositories/:repo_id/events"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/events"
  

```


## [:GET] /repositories/:repo_id/events 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/events"
  

```


## [:POST] /repositories/:repo_id/events/:id 

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
"linked_agents":[{ "ref":"/agents/people/274",
"role":"transmitter"}],
"linked_records":[{ "ref":"/repositories/2/accessions/97",
"role":"outcome"}],
"date":{ "jsonmodel_type":"date",
"date_type":"inclusive",
"label":"creation",
"begin":"1982-06-17",
"end":"1982-06-17",
"expression":"RF493XW"},
"event_type":"processed"}' \
  "http://localhost:8089//repositories/:repo_id/events/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/events/1"
  

```


## [:GET] /repositories/:repo_id/events/:id 

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
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/events/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"VHVEY"' \
  "http://localhost:8089//repositories/:repo_id/events/1"
  

```


## [:DELETE] /repositories/:repo_id/events/:id 

__Description__

Delete an event record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/events/1"
  

```


## [:POST] /repositories/:repo_id/events/:id/suppressed 

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


## [:GET] /repositories/:repo_id/find_by_id/archival_objects 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/find_by_id/archival_objects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"MISVB"' \
  "http://localhost:8089//repositories/:repo_id/find_by_id/archival_objects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"412LAH468"' \
  "http://localhost:8089//repositories/:repo_id/find_by_id/archival_objects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"R365IQT"' \
  "http://localhost:8089//repositories/:repo_id/find_by_id/archival_objects"
  

```


## [:GET] /repositories/:repo_id/find_by_id/digital_object_components 

__Description__

Find Digital Object Components by component_id

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] component_id -- A set of record component IDs

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- JSON array of refs


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/find_by_id/digital_object_components"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"470A460MM"' \
  "http://localhost:8089//repositories/:repo_id/find_by_id/digital_object_components"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"OII266O"' \
  "http://localhost:8089//repositories/:repo_id/find_by_id/digital_object_components"
  

```


## [:POST] /repositories/:repo_id/groups 

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
"description":"Description: 268",
"member_usernames":[],
"grants_permissions":[],
"group_code":"779EN956W"}' \
  "http://localhost:8089//repositories/:repo_id/groups"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/groups"
  

```


## [:GET] /repositories/:repo_id/groups 

__Description__

Get a list of groups for a repository

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String group_code -- Get groups by group code

__Returns__

	200 -- [(:resource)]


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/groups"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"WQMD852"' \
  "http://localhost:8089//repositories/:repo_id/groups"
  

```


## [:POST] /repositories/:repo_id/groups/:id 

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
"description":"Description: 268",
"member_usernames":[],
"grants_permissions":[],
"group_code":"779EN956W"}' \
  "http://localhost:8089//repositories/:repo_id/groups/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/groups/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/groups/1"
  

```


## [:GET] /repositories/:repo_id/groups/:id 

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
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/groups/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/groups/1"
  

```


## [:DELETE] /repositories/:repo_id/groups/:id 

__Description__

Delete a group by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:group)
	404 -- Not found


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/groups/1"
  

```


## [:POST] /repositories/:repo_id/jobs 

__Description__

Create a new job

__Parameters__


	JSONModel(:job) <request body> -- The job object

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"job",
"status":"queued",
"job":{ "jsonmodel_type":"import_job",
"filenames":["C901419YU",
"498BRRU",
"M66QFX",
"119BNB465"],
"import_type":"marcxml"}}' \
  "http://localhost:8089//repositories/:repo_id/jobs"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs"
  

```


## [:GET] /repositories/:repo_id/jobs 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs"
  

```


## [:DELETE] /repositories/:repo_id/jobs/:id 

__Description__

Delete a Job

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1"
  

```


## [:GET] /repositories/:repo_id/jobs/:id 

__Description__

Get a Job by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:job)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BP169228F"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1"
  

```


## [:POST] /repositories/:repo_id/jobs/:id/cancel 

__Description__

Cancel a Job

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


## [:GET] /repositories/:repo_id/jobs/:id/log 

__Description__

Get a Job's log by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::NonNegativeInteger offset -- The byte offset of the log file to show

__Returns__

	200 -- The section of the import log between 'offset' and the end of file


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1/log"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"NonNegativeInteger"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1/log"
  

```


## [:GET] /repositories/:repo_id/jobs/:id/output_files 

__Description__

Get a list of Job's output files by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- An array of output files


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1/output_files"
  

```


## [:GET] /repositories/:repo_id/jobs/:id/output_files/:file_id 

__Description__

Get a Job's output file by ID

__Parameters__


	Integer id -- The ID of the record

	Integer file_id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- Returns the file


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1/output_files/:file_id"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1/output_files/:file_id"
  

```


## [:GET] /repositories/:repo_id/jobs/:id/records 

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
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/1/records"
  

```


## [:GET] /repositories/:repo_id/jobs/active 

__Description__

Get a list of all active Jobs for a Repository

__Parameters__


	[String] resolve -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:job)]


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"OGSFM"' \
  "http://localhost:8089//repositories/:repo_id/jobs/active"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/active"
  

```


## [:GET] /repositories/:repo_id/jobs/archived 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"TDE552736"' \
  "http://localhost:8089//repositories/:repo_id/jobs/archived"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/archived"
  

```


## [:GET] /repositories/:repo_id/jobs/import_types 

__Description__

List all supported import job types

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- A list of supported import types


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs/import_types"
  

```


## [:POST] /repositories/:repo_id/jobs_with_files 

__Description__

Create a new job and post input files

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
"job":{ "jsonmodel_type":"import_job",
"filenames":["C901419YU",
"498BRRU",
"M66QFX",
"119BNB465"],
"import_type":"marcxml"}}' \
  "http://localhost:8089//repositories/:repo_id/jobs_with_files"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"UploadFile"' \
  "http://localhost:8089//repositories/:repo_id/jobs_with_files"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/jobs_with_files"
  

```


## [:POST] /repositories/:repo_id/preferences 

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


## [:GET] /repositories/:repo_id/preferences 

__Description__

Get a list of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer user_id -- The username to retrieve defaults for

__Returns__

	200 -- [(:preference)]


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/preferences"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/preferences"
  

```


## [:GET] /repositories/:repo_id/preferences/:id 

__Description__

Get a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:preference)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/preferences/1"
  

```


## [:POST] /repositories/:repo_id/preferences/:id 

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


## [:DELETE] /repositories/:repo_id/preferences/:id 

__Description__

Delete a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/preferences/1"
  

```


## [:GET] /repositories/:repo_id/preferences/defaults 

__Description__

Get the default set of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String username -- The username to retrieve defaults for

__Returns__

	200 -- (defaults)


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/preferences/defaults"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"394M849E12"' \
  "http://localhost:8089//repositories/:repo_id/preferences/defaults"
  

```


## [:POST] /repositories/:repo_id/rde_templates 

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


## [:GET] /repositories/:repo_id/rde_templates 

__Description__

Get a list of RDE Templates

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:rde_template)]


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/rde_templates"
  

```


## [:GET] /repositories/:repo_id/rde_templates/:id 

__Description__

Get an RDE template record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:rde_template)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/rde_templates/1"
  

```


## [:DELETE] /repositories/:repo_id/rde_templates/:id 

__Description__

Delete an RDE Template

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/rde_templates/1"
  

```


## [:GET] /repositories/:repo_id/resource_descriptions/:id.:fmt/metadata 

__Description__

Get export metadata for a Resource Description

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	String fmt -- Format of the request

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.:fmt/metadata"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"HHMV656"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/resource_descriptions/:id.pdf 

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
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.pdf"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.pdf"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.pdf"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.pdf"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.pdf"
  

```


## [:GET] /repositories/:repo_id/resource_descriptions/:id.xml 

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
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.xml"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.xml"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.xml"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.xml"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resource_descriptions/1.xml"
  

```


## [:GET] /repositories/:repo_id/resource_labels/:id.:fmt/metadata 

__Description__

Get export metadata for Resource labels

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resource_labels/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/resource_labels/:id.tsv 

__Description__

Get a tsv list of printable labels for a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resource_labels/1.tsv"
  

```


## [:POST] /repositories/:repo_id/resources 

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
"portion":"part",
"number":"88",
"extent_type":"cassettes"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"creation",
"begin":"2014-10-30",
"end":"2014-10-30",
"expression":"NV559870884"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"759WVO21",
"description":"967EYH704"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"books",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"frame",
"indicator_1":"1850-6234",
"barcode_1":"01110100000111000100",
"container_extent":"47",
"container_extent_type":"sheets"}},
{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"moving_images",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"folder",
"indicator_1":"38-2330-01",
"barcode_1":"00101011011100011011",
"container_extent":"79",
"container_extent_type":"gigabytes"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>122</emph>",
"id_0":"LA952PU",
"level":"subfonds",
"language":"grn",
"ead_id":"367RJ289W",
"finding_aid_date":"GT516SL",
"ead_location":"BB188WQ"}' \
  "http://localhost:8089//repositories/:repo_id/resources"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources"
  

```


## [:GET] /repositories/:repo_id/resources 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources"
  

```


## [:GET] /repositories/:repo_id/resources/:id 

__Description__

Get a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:resource)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"HLQDK"' \
  "http://localhost:8089//repositories/:repo_id/resources/1"
  

```


## [:POST] /repositories/:repo_id/resources/:id 

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
"portion":"part",
"number":"88",
"extent_type":"cassettes"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"creation",
"begin":"2014-10-30",
"end":"2014-10-30",
"expression":"NV559870884"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"759WVO21",
"description":"967EYH704"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"books",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"frame",
"indicator_1":"1850-6234",
"barcode_1":"01110100000111000100",
"container_extent":"47",
"container_extent_type":"sheets"}},
{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"moving_images",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"folder",
"indicator_1":"38-2330-01",
"barcode_1":"00101011011100011011",
"container_extent":"79",
"container_extent_type":"gigabytes"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>122</emph>",
"id_0":"LA952PU",
"level":"subfonds",
"language":"grn",
"ead_id":"367RJ289W",
"finding_aid_date":"GT516SL",
"ead_location":"BB188WQ"}' \
  "http://localhost:8089//repositories/:repo_id/resources/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1"
  

```


## [:DELETE] /repositories/:repo_id/resources/:id 

__Description__

Delete a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1"
  

```


## [:POST] /repositories/:repo_id/resources/:id/accept_children 

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
  -d '"488CYQ18"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/accept_children"
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/accept_children"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/accept_children"
  

```


## [:POST] /repositories/:repo_id/resources/:id/children 

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


## [:GET] /repositories/:repo_id/resources/:id/models_in_graph 

__Description__

Get a list of record types in the graph of a resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/models_in_graph"
  

```


## [:GET] /repositories/:repo_id/resources/:id/ordered_records 

__Description__

Get the list of URIs of this resource and all archival objects contained within.Ordered by tree order (i.e. if you fully expanded the record tree and read from top to bottom)

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- JSONModel(:resource_ordered_records)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/ordered_records"
  

```


## [:POST] /repositories/:repo_id/resources/:id/publish 

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


## [:POST] /repositories/:repo_id/resources/:id/suppressed 

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


## [:POST] /repositories/:repo_id/resources/:id/transfer 

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
  -d '"891N805LH"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/transfer"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/transfer"
  

```


## [:GET] /repositories/:repo_id/resources/:id/tree 

__Description__

Get a Resource tree

__Parameters__


	Integer id -- The ID of the record

	String limit_to -- An Archival Object URI or 'root'

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"OQC434712"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree"
  

```


## [:GET] /repositories/:repo_id/resources/:id/tree/node 

__Description__

Fetch tree information for an Archival Object record within a tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	String node_uri -- The URI of the Archival Object record of interest

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON object describing enough information about a specific node.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint

  * position -- the logical position of this record within its subtree

  * precomputed_waypoints -- a collection of arrays (keyed on child URI) in the
    same format as returned by the '/waypoint' endpoint.  Since a fetch for a
    given node is almost always followed by a fetch of the first waypoint, using
    the information in this structure can save a backend call.


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/node"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"49845124391383"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/node"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/node"
  

```


## [:GET] /repositories/:repo_id/resources/:id/tree/node_from_root 

__Description__

Fetch tree paths from the root record to Archival Objects

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[Integer] node_ids -- The IDs of the Archival Object records of interest

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON array describing the path to a node, starting from the root of the tree.  Each path element provides:

  * node -- the URI of the node to next expand

  * offset -- the waypoint number within `node` that contains the next entry in
    the path (or the desired record, if we're at the end of the path)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/node_from_root"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/node_from_root"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/node_from_root"
  

```


## [:GET] /repositories/:repo_id/resources/:id/tree/root 

__Description__

Fetch tree information for the top-level resource record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON object describing enough information about this tree's root record to render the rest.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/root"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/root"
  

```


## [:GET] /repositories/:repo_id/resources/:id/tree/waypoint 

__Description__

Fetch the record slice for a given tree waypoint

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer offset -- The page of records to return

	String parent_node -- The URI of the parent of this waypoint (none for the root record)

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/waypoint"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/waypoint"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"F875IGV"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/waypoint"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/resources/1/tree/waypoint"
  

```


## [:GET] /repositories/:repo_id/resources/marc21/:id.:fmt/metadata 

__Description__

Get metadata for a MARC21 export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/marc21/1.:fmt/metadata"
  

```


## [:GET] /repositories/:repo_id/resources/marc21/:id.xml 

__Description__

Get a MARC 21 representation of a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources/marc21/1.xml"
  

```


## [:GET, :POST] /repositories/:repo_id/search 

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

	Integer facet_mincount -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter -- A json string containing the advanced query to filter by

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"R983W53F"' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"764824V41O"' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"Q864653H489"' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"XLH673389"' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"G890DOV"' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"R366674Q708"' \
  "http://localhost:8089//repositories/:repo_id/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"QUS703W"' \
  "http://localhost:8089//repositories/:repo_id/search"
  

```


## [:POST] /repositories/:repo_id/top_containers 

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
"indicator":"NB832672264",
"type":"frame",
"barcode":"4cd6cfb2cc03e5649de5e3de7653d34a",
"ils_holding_id":"887386M71117",
"ils_item_id":"UV170VH",
"exported_to_ils":"2017-05-02T08:28:42-04:00"}' \
  "http://localhost:8089//repositories/:repo_id/top_containers"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers"
  

```


## [:GET] /repositories/:repo_id/top_containers 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers"
  

```


## [:POST] /repositories/:repo_id/top_containers/:id 

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
"indicator":"NB832672264",
"type":"frame",
"barcode":"4cd6cfb2cc03e5649de5e3de7653d34a",
"ils_holding_id":"887386M71117",
"ils_item_id":"UV170VH",
"exported_to_ils":"2017-05-02T08:28:42-04:00"}' \
  "http://localhost:8089//repositories/:repo_id/top_containers/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/1"
  

```


## [:GET] /repositories/:repo_id/top_containers/:id 

__Description__

Get a top container by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:top_container)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BC997HV"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/1"
  

```


## [:DELETE] /repositories/:repo_id/top_containers/:id 

__Description__

Delete a top container

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/1"
  

```


## [:POST] /repositories/:repo_id/top_containers/batch/container_profile 

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
  -d '"280X680CC"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/container_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/container_profile"
  

```


## [:POST] /repositories/:repo_id/top_containers/batch/ils_holding_id 

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
  -d '"55B708657216"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/ils_holding_id"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/ils_holding_id"
  

```


## [:POST] /repositories/:repo_id/top_containers/batch/location 

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
  -d '"847WUW936"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/location"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/location"
  

```


## [:POST] /repositories/:repo_id/top_containers/bulk/barcodes 

__Description__

Bulk update barcodes

__Parameters__


	String <request body> -- JSON string containing barcode data {uri=>barcode}

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"R144LUH"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/barcodes"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/barcodes"
  

```


## [:POST] /repositories/:repo_id/top_containers/bulk/locations 

__Description__

Bulk update locations

__Parameters__


	String <request body> -- JSON string containing location data {container_uri=>location_uri}

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"F392U14V"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/locations"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/locations"
  

```


## [:GET] /repositories/:repo_id/top_containers/search 

__Description__

Search for top containers

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String q -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq -- A json string containing the advanced query

	[String] type -- The record type to search (defaults to all types if not specified)

	String sort -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet -- The list of the fields to produce facets for

	Integer facet_mincount -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter -- A json string containing the advanced query to filter by

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- [(:top_container)]


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"WB766198X"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"ERMIP"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"KWM424H"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"56P312489424"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"CRRO530"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"NDV765G"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"685F443PY"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/search"
  

```


## [:POST] /repositories/:repo_id/transfer 

__Description__

Transfer this record to a different repository

__Parameters__


	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"91394XJM"' \
  "http://localhost:8089//repositories/:repo_id/transfer"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/transfer"
  

```


## [:GET] /repositories/:repo_id/users/:id 

__Description__

Get a user's details including their groups for the current repository

__Parameters__


	Integer id -- The username id to fetch

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:user)


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/users/1"
  

```


## [:POST] /repositories/with_agent 

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


## [:GET] /repositories/with_agent/:id 

__Description__

Get a Repository by ID, including its agent representation

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:repository_with_agent)
	404 -- Not found


```shell 
    
  

```


## [:POST] /repositories/with_agent/:id 

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


## [:GET] /schemas 

__Description__

Get all ArchivesSpace schemas

__Parameters__


__Returns__

	200 -- ArchivesSpace (schemas)


```shell 
  

```


## [:GET] /schemas/:schema 

__Description__

Get an ArchivesSpace schema

__Parameters__


	String schema -- Schema name to retrieve

__Returns__

	200 -- ArchivesSpace (:schema)
	404 -- Schema not found


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"V761DJC"' \
  "http://localhost:8089//schemas/:schema"
  

```


## [:GET, :POST] /search 

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

	Integer facet_mincount -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter -- A json string containing the advanced query to filter by

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"FYLLW"' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"FLAJ154"' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"ER689RY"' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"SF943536812"' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"UXX370N"' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"ODBXP"' \
  "http://localhost:8089//search"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"QFCTP"' \
  "http://localhost:8089//search"
  

```


## [:GET] /search/location_profile 

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

	Integer facet_mincount -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter -- A json string containing the advanced query to filter by

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"527Y299C330"' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"N688XY203"' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"454NP581Y"' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"842CQPH"' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"A518257MB"' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"909NQHR"' \
  "http://localhost:8089//search/location_profile"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"FQ601IV"' \
  "http://localhost:8089//search/location_profile"
  

```


## [:GET] /search/published_tree 

__Description__

Find the tree view for a particular archival record

__Parameters__


	String node_uri -- The URI of the archival record to find the tree view for

__Returns__

	200 -- OK
	404 -- Not found


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"J350Q935T"' \
  "http://localhost:8089//search/published_tree"
  

```


## [:GET, :POST] /search/record_types_by_repository 

__Description__

Return the counts of record types of interest by repository

__Parameters__


	[String] record_types -- The list of record types to tally

	String repo_uri -- An optional repository URI.  If given, just return counts for the single repository

__Returns__

	200 -- If repository is given, returns a map like {'record_type' => <count>}.  Otherwise, {'repo_uri' => {'record_type' => <count>}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"K218G11C"' \
  "http://localhost:8089//search/record_types_by_repository"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"536YOPI"' \
  "http://localhost:8089//search/record_types_by_repository"
  

```


## [:GET, :POST] /search/records 

__Description__

Return a set of records by URI

__Parameters__


	[String] uri -- The list of record URIs to fetch

	[String] resolve -- The list of result fields to resolve (if any)

__Returns__

	200 -- a JSON map of records


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"S169W992Q"' \
  "http://localhost:8089//search/records"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"LMV774T"' \
  "http://localhost:8089//search/records"
  

```


## [:GET, :POST] /search/repositories 

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

	Integer facet_mincount -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter -- A json string containing the advanced query to filter by

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"383D489X769"' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"929B82759E"' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"48D880998I"' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"XP383HJ"' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"505947BJC"' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"LDUAC"' \
  "http://localhost:8089//search/repositories"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"ICFX900"' \
  "http://localhost:8089//search/repositories"
  

```


## [:GET, :POST] /search/subjects 

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

	Integer facet_mincount -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter -- A json string containing the advanced query to filter by

	[String] exclude -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl -- Whether to use highlighting

	String root_record -- Search within a collection of records (defined by the record at the root of the tree)

	String dt -- Format to return (JSON default)

__Returns__

	200 -- 


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"735BQ124M"' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"MCDT825"' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"HM812XP"' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"OO19US"' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"MD851WU"' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"489HSR106"' \
  "http://localhost:8089//search/subjects"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"CS362LH"' \
  "http://localhost:8089//search/subjects"
  

```


## [:GET] /space_calculator/buildings 

__Description__

Get a Location by ID

__Parameters__


__Returns__

	200 -- Location building data as JSON


```shell 
  

```


## [:GET] /space_calculator/by_building 

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
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"P896RLB"' \
  "http://localhost:8089//space_calculator/by_building"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"XKKVV"' \
  "http://localhost:8089//space_calculator/by_building"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"223SU796M"' \
  "http://localhost:8089//space_calculator/by_building"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"S45483207W"' \
  "http://localhost:8089//space_calculator/by_building"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"939211EEE"' \
  "http://localhost:8089//space_calculator/by_building"
  

```


## [:GET] /space_calculator/by_location 

__Description__

Calculate how many containers will fit in a list of locations

__Parameters__


	String container_profile_uri -- The uri of the container profile

	[String] location_uris -- A list of location uris to calculate space for

__Returns__

	200 -- Calculation results


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"MA223YO"' \
  "http://localhost:8089//space_calculator/by_location"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"48654317272837"' \
  "http://localhost:8089//space_calculator/by_location"
  

```


## [:POST] /subjects 

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
"used_within_repositories":[],
"terms":[{ "jsonmodel_type":"term",
"term":"Term 132",
"term_type":"temporal",
"vocabulary":"/vocabularies/156"}],
"external_documents":[],
"vocabulary":"/vocabularies/157",
"authority_id":"http://www.example-482.com",
"scope_note":"525M161U121",
"source":"mesh"}' \
  "http://localhost:8089//subjects"
  

```


## [:GET] /subjects 

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
  

```


## [:POST] /subjects/:id 

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
"used_within_repositories":[],
"terms":[{ "jsonmodel_type":"term",
"term":"Term 132",
"term_type":"temporal",
"vocabulary":"/vocabularies/156"}],
"external_documents":[],
"vocabulary":"/vocabularies/157",
"authority_id":"http://www.example-482.com",
"scope_note":"525M161U121",
"source":"mesh"}' \
  "http://localhost:8089//subjects/1"
  

```


## [:GET] /subjects/:id 

__Description__

Get a Subject by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:subject)


```shell 
    
  

```


## [:DELETE] /subjects/:id 

__Description__

Delete a Subject

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted


```shell 
    
  

```


## [:GET] /terms 

__Description__

Get a list of Terms matching a prefix

__Parameters__


	String q -- The prefix to match

__Returns__

	200 -- [(:term)]


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"W458785313B"' \
  "http://localhost:8089//terms"
  

```


## [:GET] /update-feed 

__Description__

Get a stream of updated records

__Parameters__


	Integer last_sequence -- The last sequence number seen

	[String] resolve -- A list of references to resolve and embed in the response

__Returns__

	200 -- a list of records and sequence numbers


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//update-feed"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"IQ692318B"' \
  "http://localhost:8089//update-feed"
  

```


## [:POST] /update_monitor 

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


## [:POST] /users 

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
  -d '"461XK377K"' \
  "http://localhost:8089//users"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"FOO884B"' \
  "http://localhost:8089//users"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_admin":false,
"username":"username_21",
"name":"Name Number 524"}' \
  "http://localhost:8089//users"
  

```


## [:GET] /users 

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
  

```


## [:GET] /users/:id 

__Description__

Get a user's details (including their current permissions)

__Parameters__


	Integer id -- The username id to fetch

__Returns__

	200 -- (:user)


```shell 
    
  

```


## [:POST] /users/:id 

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
  -d '"640IH115712"' \
  "http://localhost:8089//users/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_admin":false,
"username":"username_21",
"name":"Name Number 524"}' \
  "http://localhost:8089//users/1"
  

```


## [:DELETE] /users/:id 

__Description__

Delete a user

__Parameters__


	Integer id -- The user to delete

__Returns__

	200 -- deleted


```shell 
    
  

```


## [:POST] /users/:id/groups 

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
  -d '"E95617C82"' \
  "http://localhost:8089//users/1/groups"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//users/1/groups"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//users/1/groups"
  

```


## [:POST] /users/:username/become-user 

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


## [:POST] /users/:username/login 

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
  -d '"458D979XW"' \
  "http://localhost:8089//users/:username/login"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//users/:username/login"
  

```


## [:GET] /users/complete 

__Description__

Get a list of system users

__Parameters__


	String query -- A prefix to search for

__Returns__

	200 -- A list of usernames


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"EHXLV"' \
  "http://localhost:8089//users/complete"
  

```


## [:GET] /users/current-user 

__Description__

Get the currently logged in user

__Parameters__


__Returns__

	200 -- (:user)
	404 -- Not logged in


```shell 
  

```


## [:GET] /version 

__Description__

Get the ArchivesSpace application version

__Parameters__


__Returns__

	200 -- ArchivesSpace (version)


```shell 
  

```


## [:POST] /vocabularies 

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


## [:GET] /vocabularies 

__Description__

Get a list of Vocabularies

__Parameters__


	String ref_id -- An alternate, externally-created ID for the vocabulary

__Returns__

	200 -- [(:vocabulary)]


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"161579WHO"' \
  "http://localhost:8089//vocabularies"
  

```


## [:POST] /vocabularies/:id 

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


## [:GET] /vocabularies/:id 

__Description__

Get a Vocabulary by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- OK


```shell 
    
  

```


## [:GET] /vocabularies/:id/terms 

__Description__

Get a list of Terms for a Vocabulary

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- [(:term)]


```shell 
    
  

```



