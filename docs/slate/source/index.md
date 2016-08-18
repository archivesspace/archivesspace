--- title: API Reference 
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
As of 2016-08-18 14:28:18 +0200 the following REST endpoints exist in the master branch of the development repository:


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


   
    <a href='#jsonmodel-agent_corporate_entity'>JSONModel(:agent_corporate_entity)</a> -- request body -- The record to create
    

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number":"544 63336 861 30704 8841",
"ext":"486T540OL"}],
"name":"Name Number 505",
"address_1":"D69478KQ",
"address_3":"XSH803L",
"region":"BD453681O",
"country":"FUYWA",
"post_code":"C48986BV",
"note":"896B142P341"}],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"1998-03-08",
"end":"1998-03-08",
"expression":"691CD67418"}],
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"primary_name":"Name Number 504",
"subordinate_name_1":"LTVA349",
"subordinate_name_2":"DYCKP",
"number":"E729SYW",
"sort_name":"SORT z - 422",
"dates":"PU607DT",
"qualifier":"621WDHA",
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
    

   
    <a href='#jsonmodel-agent_corporate_entity'>JSONModel(:agent_corporate_entity)</a> -- request body -- The updated record
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number":"544 63336 861 30704 8841",
"ext":"486T540OL"}],
"name":"Name Number 505",
"address_1":"D69478KQ",
"address_3":"XSH803L",
"region":"BD453681O",
"country":"FUYWA",
"post_code":"C48986BV",
"note":"896B142P341"}],
"linked_agent_roles":[],
"external_documents":[],
"rights_statements":[],
"notes":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"existence",
"begin":"1998-03-08",
"end":"1998-03-08",
"expression":"691CD67418"}],
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"primary_name":"Name Number 504",
"subordinate_name_1":"LTVA349",
"subordinate_name_2":"DYCKP",
"number":"E729SYW",
"sort_name":"SORT z - 422",
"dates":"PU607DT",
"qualifier":"621WDHA",
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


   
    <a href='#jsonmodel-agent_family'>JSONModel(:agent_family)</a> -- request body -- The record to create
    

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
"date_type":"inclusive",
"label":"existence",
"begin":"1992-11-16",
"end":"1992-11-16",
"expression":"20I953US"}],
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"family_name":"Name Number 506",
"sort_name":"SORT u - 423",
"dates":"LD650889832",
"qualifier":"QN913460I",
"prefix":"238464DTW",
"authority_id":"http://www.example-469.com",
"source":"nad"}],
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
    

   
    <a href='#jsonmodel-agent_family'>JSONModel(:agent_family)</a> -- request body -- The updated record
    

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
"date_type":"inclusive",
"label":"existence",
"begin":"1992-11-16",
"end":"1992-11-16",
"expression":"20I953US"}],
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"family_name":"Name Number 506",
"sort_name":"SORT u - 423",
"dates":"LD650889832",
"qualifier":"QN913460I",
"prefix":"238464DTW",
"authority_id":"http://www.example-469.com",
"source":"nad"}],
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


   
    <a href='#jsonmodel-agent_person'>JSONModel(:agent_person)</a> -- request body -- The record to create
    

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
"begin":"2010-12-04",
"end":"2010-12-04",
"expression":"KXBW56"}],
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"source":"local",
"primary_name":"Name Number 507",
"sort_name":"SORT l - 424",
"name_order":"inverted",
"number":"AWVNS",
"dates":"930987ASO",
"qualifier":"TH932FI",
"fuller_form":"YDD468B",
"prefix":"VE672XR",
"title":"CJJNS",
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
    

   
    <a href='#jsonmodel-agent_person'>JSONModel(:agent_person)</a> -- request body -- The updated record
    

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
"begin":"2010-12-04",
"end":"2010-12-04",
"expression":"KXBW56"}],
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"source":"local",
"primary_name":"Name Number 507",
"sort_name":"SORT l - 424",
"name_order":"inverted",
"number":"AWVNS",
"dates":"930987ASO",
"qualifier":"TH932FI",
"fuller_form":"YDD468B",
"prefix":"VE672XR",
"title":"CJJNS",
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


   
    <a href='#jsonmodel-agent_software'>JSONModel(:agent_software)</a> -- request body -- The record to create
    

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
"date_type":"inclusive",
"label":"existence",
"begin":"2007-12-10",
"end":"2007-12-10",
"expression":"ICLX448"}],
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"software_name":"Name Number 508",
"sort_name":"SORT q - 425"}],
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
    

   
    <a href='#jsonmodel-agent_software'>JSONModel(:agent_software)</a> -- request body -- The updated record
    

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
"date_type":"inclusive",
"label":"existence",
"begin":"2007-12-10",
"end":"2007-12-10",
"expression":"ICLX448"}],
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"software_name":"Name Number 508",
"sort_name":"SORT q - 425"}],
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
  -d '"EWO428D"' \
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
    

   
    <a href='#jsonmodel-enumeration_value'>JSONModel(:enumeration_value)</a> -- request body -- The enumeration value to update
    

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


   
    <a href='#jsonmodel-enumeration'>JSONModel(:enumeration)</a> -- request body -- The record to create
    

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
    

   
    <a href='#jsonmodel-enumeration'>JSONModel(:enumeration)</a> -- request body -- The enumeration to update
    

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


   
    <a href='#jsonmodel-enumeration_migration'>JSONModel(:enumeration_migration)</a> -- request body -- The migration request
    

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


   
    <a href='#jsonmodel-container_profile'>JSONModel(:container_profile)</a> -- request body -- The record to create
    

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"S59MYQ",
"url":"325CR213L",
"dimension_units":"inches",
"extent_dimension":"width",
"depth":"68",
"height":"89",
"width":"98"}' \
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
    

   
    <a href='#jsonmodel-container_profile'>JSONModel(:container_profile)</a> -- request body -- The updated record
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"S59MYQ",
"url":"325CR213L",
"dimension_units":"inches",
"extent_dimension":"width",
"depth":"68",
"height":"89",
"width":"98"}' \
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


   
    <a href='#jsonmodel-location_profile'>JSONModel(:location_profile)</a> -- request body -- The record to create
    

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"P619835LK",
"dimension_units":"inches",
"depth":"6",
"height":"82",
"width":"14"}' \
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
    

   
    <a href='#jsonmodel-location_profile'>JSONModel(:location_profile)</a> -- request body -- The updated record
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"P619835LK",
"dimension_units":"inches",
"depth":"6",
"height":"82",
"width":"14"}' \
  "http://localhost:8089//location_profiles/1"
  

```


## POST /locations 

__Description__

Create a Location

__Parameters__


   
    <a href='#jsonmodel-location'>JSONModel(:location)</a> -- request body -- The record to create
    

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location",
"external_ids":[],
"functions":[],
"building":"169 W 9th Street",
"floor":"2",
"room":"1",
"area":"Front",
"barcode":"00111011010100101101",
"temporary":"loan"}' \
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
    

   
    <a href='#jsonmodel-location'>JSONModel(:location)</a> -- request body -- The updated record
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location",
"external_ids":[],
"functions":[],
"building":"169 W 9th Street",
"floor":"2",
"room":"1",
"area":"Front",
"barcode":"00111011010100101101",
"temporary":"loan"}' \
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
    

   
    <a href='#jsonmodel-location_batch'>JSONModel(:location_batch)</a> -- request body -- The location batch data to generate all locations
    

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


   
    <a href='#jsonmodel-location_batch_update'>JSONModel(:location_batch_update)</a> -- request body -- The location batch data to update all locations
    

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


   
    <a href='#jsonmodel-merge_request'>JSONModel(:merge_request)</a> -- request body -- A merge request
    

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
    

   
    <a href='#jsonmodel-merge_request'>JSONModel(:merge_request)</a> -- request body -- A merge request
    

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
    

   
    <a href='#jsonmodel-merge_request'>JSONModel(:merge_request)</a> -- request body -- A merge request
    

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


   
    <a href='#jsonmodel-merge_request'>JSONModel(:merge_request)</a> -- request body -- A merge request
    

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


   
    <a href='#jsonmodel-repository'>JSONModel(:repository)</a> -- request body -- The record to create
    

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
    

   
    <a href='#jsonmodel-repository'>JSONModel(:repository)</a> -- request body -- The updated record
    

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


   
    <a href='#jsonmodel-accession'>JSONModel(:accession)</a> -- request body -- The record to create
    

  
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
"id_0":"720357BOL",
"id_1":"855C978BN",
"id_2":"F607730L626",
"id_3":"PXRQL",
"title":"Accession Title: 348",
"content_description":"Description: 259",
"condition_description":"Description: 260",
"accession_date":"2010-12-05"}' \
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
    

   
    <a href='#jsonmodel-accession'>JSONModel(:accession)</a> -- request body -- The updated record
    

  
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
"id_0":"720357BOL",
"id_1":"855C978BN",
"id_2":"F607730L626",
"id_3":"PXRQL",
"title":"Accession Title: 348",
"content_description":"Description: 259",
"condition_description":"Description: 260",
"accession_date":"2010-12-05"}' \
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
  -d '"TR360FB"' \
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


   
    <a href='#jsonmodel-archival_object'>JSONModel(:archival_object)</a> -- request body -- The record to create
    

  
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
"ref_id":"632GYBL",
"level":"subseries",
"title":"Archival Object Title: 349"}' \
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
    

   
    <a href='#jsonmodel-archival_object'>JSONModel(:archival_object)</a> -- request body -- The updated record
    

  
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
"ref_id":"632GYBL",
"level":"subseries",
"title":"Archival Object Title: 349"}' \
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
  -d '"DCH894413"' \
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


   
    <a href='#jsonmodel-archival_record_children'>JSONModel(:archival_record_children)</a> -- request body -- The children to add to the archival object
    

  
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
    

  
    String migration -- param to indicate we are using a migrator
    

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
  -d '"VL100136U"' \
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


   
    <a href='#jsonmodel-classification_term'>JSONModel(:classification_term)</a> -- request body -- The record to create
    

  
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
    

   
    <a href='#jsonmodel-classification_term'>JSONModel(:classification_term)</a> -- request body -- The updated record
    

  
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
  -d '"WI714GE"' \
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


   
    <a href='#jsonmodel-classification'>JSONModel(:classification)</a> -- request body -- The record to create
    

  
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
"identifier":"DOBP477",
"title":"Classification Title: 350",
"description":"Description: 261"}' \
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
    

   
    <a href='#jsonmodel-classification'>JSONModel(:classification)</a> -- request body -- The updated record
    

  
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
"identifier":"DOBP477",
"title":"Classification Title: 350",
"description":"Description: 261"}' \
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
  -d '"EJ848VS"' \
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
  -d '"ICMQE"' \
  "http://localhost:8089//repositories/:repo_id/component_transfers"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"109P761GN"' \
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


   
    <a href='#jsonmodel-default_values'>JSONModel(:default_values)</a> -- request body -- The default values set
    

  
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
  -d '"425P402R809"' \
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


   
    <a href='#jsonmodel-digital_object_component'>JSONModel(:digital_object_component)</a> -- request body -- The record to create
    

  
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
"component_id":"733E691LN",
"title":"Digital Object Component Title: 353"}' \
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
    

   
    <a href='#jsonmodel-digital_object_component'>JSONModel(:digital_object_component)</a> -- request body -- The updated record
    

  
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
"component_id":"733E691LN",
"title":"Digital Object Component Title: 353"}' \
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
  -d '"739YCQS"' \
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


   
    <a href='#jsonmodel-digital_record_children'>JSONModel(:digital_record_children)</a> -- request body -- The children to add to the digital object component
    

  
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


   
    <a href='#jsonmodel-digital_object'>JSONModel(:digital_object)</a> -- request body -- The record to create
    

  
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
"number":"15",
"extent_type":"volumes"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"2015-10-09",
"end":"2015-10-09",
"expression":"897T872OG"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"R84C16887",
"use_statement":"text-ocr-edited",
"xlink_actuate_attribute":"onRequest",
"xlink_show_attribute":"none",
"file_format_name":"aiff",
"file_format_version":"JJSFC",
"file_size_bytes":93,
"checksum":"CJB387820",
"checksum_method":"sha-512"},
{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"672E986DR",
"use_statement":"text-codebook",
"xlink_actuate_attribute":"other",
"xlink_show_attribute":"none",
"file_format_name":"tiff",
"file_format_version":"EG958623O",
"file_size_bytes":11,
"checksum":"587D431616J",
"checksum_method":"sha-1"}],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 352",
"language":"nzi",
"digital_object_id":"49CWN191"}' \
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
    

   
    <a href='#jsonmodel-digital_object'>JSONModel(:digital_object)</a> -- request body -- The updated record
    

  
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
"number":"15",
"extent_type":"volumes"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"2015-10-09",
"end":"2015-10-09",
"expression":"897T872OG"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"R84C16887",
"use_statement":"text-ocr-edited",
"xlink_actuate_attribute":"onRequest",
"xlink_show_attribute":"none",
"file_format_name":"aiff",
"file_format_version":"JJSFC",
"file_size_bytes":93,
"checksum":"CJB387820",
"checksum_method":"sha-512"},
{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"672E986DR",
"use_statement":"text-codebook",
"xlink_actuate_attribute":"other",
"xlink_show_attribute":"none",
"file_format_name":"tiff",
"file_format_version":"EG958623O",
"file_size_bytes":11,
"checksum":"587D431616J",
"checksum_method":"sha-1"}],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 352",
"language":"nzi",
"digital_object_id":"49CWN191"}' \
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
  -d '"NJ255221R"' \
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


   
    <a href='#jsonmodel-digital_record_children'>JSONModel(:digital_record_children)</a> -- request body -- The component children to add to the digital object
    

  
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
  -d '"QBVUI"' \
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


   
    <a href='#jsonmodel-event'>JSONModel(:event)</a> -- request body -- The record to create
    

  
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
"linked_records":[{ "ref":"/repositories/2/accessions/98",
"role":"transfer"}],
"date":{ "jsonmodel_type":"date",
"date_type":"range",
"label":"creation",
"begin":"1971-09-26",
"end":"1971-09-26",
"expression":"SA768GE"},
"event_type":"custody_transfer"}' \
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
    

   
    <a href='#jsonmodel-event'>JSONModel(:event)</a> -- request body -- The updated record
    

  
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
"linked_records":[{ "ref":"/repositories/2/accessions/98",
"role":"transfer"}],
"date":{ "jsonmodel_type":"date",
"date_type":"range",
"label":"creation",
"begin":"1971-09-26",
"end":"1971-09-26",
"expression":"SA768GE"},
"event_type":"custody_transfer"}' \
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


   
    <a href='#jsonmodel-group'>JSONModel(:group)</a> -- request body -- The record to create
    

  
    Integer repo_id -- The Repository ID -- The Repository must exist
    

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- conflict


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 266",
"member_usernames":[],
"grants_permissions":[],
"group_code":"KHIEE"}' \
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
    

   
    <a href='#jsonmodel-group'>JSONModel(:group)</a> -- request body -- The updated record
    

  
    Integer repo_id -- The Repository ID -- The Repository must exist
    

  
    RESTHelpers::BooleanParam with_members -- If 'true' (the default) replace the membership list with the list provided
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}
	409 -- conflict


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 266",
"member_usernames":[],
"grants_permissions":[],
"group_code":"KHIEE"}' \
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


   
    <a href='#jsonmodel-job'>JSONModel(:job)</a> -- request body -- The job object
    

  
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


   
    <a href='#jsonmodel-job'>JSONModel(:job)</a> job -- 
    

  
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


   
    <a href='#jsonmodel-preference'>JSONModel(:preference)</a> -- request body -- The record to create
    

  
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
    

   
    <a href='#jsonmodel-preference'>JSONModel(:preference)</a> -- request body -- The updated record
    

  
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


   
    <a href='#jsonmodel-rde_template'>JSONModel(:rde_template)</a> -- request body -- The record to create
    

  
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


## POST /repositories/:repo_id/resources 

__Description__

Create a Resource

__Parameters__


   
    <a href='#jsonmodel-resource'>JSONModel(:resource)</a> -- request body -- The record to create
    

  
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
"number":"68",
"extent_type":"cassettes"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"2004-04-05",
"end":"2004-04-05",
"expression":"60164299OO"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"K12565249973",
"description":"OT291GS"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"graphic_materials",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"frame",
"indicator_1":"44-65",
"barcode_1":"01000010110011111001",
"container_extent":"23",
"container_extent_type":"sheets"}},
{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"maps",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"box",
"indicator_1":"6208-0841-17-802",
"barcode_1":"11011110101101110100",
"container_extent":"38",
"container_extent_type":"gigabytes"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>88</emph>",
"id_0":"CXNYY",
"level":"collection",
"language":"kal",
"finding_aid_description_rules":"cco",
"finding_aid_date":"HUXC514",
"finding_aid_language":"719434Y792D",
"ead_location":"Y188RLF"}' \
  "http://localhost:8089//repositories/:repo_id/resources"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/resources"
  

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


## POST /repositories/:repo_id/resources/:id 

__Description__

Update a Resource

__Parameters__


  
    Integer id -- The ID of the record
    

   
    <a href='#jsonmodel-resource'>JSONModel(:resource)</a> -- request body -- The updated record
    

  
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
"number":"68",
"extent_type":"cassettes"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"2004-04-05",
"end":"2004-04-05",
"expression":"60164299OO"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"K12565249973",
"description":"OT291GS"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"graphic_materials",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"frame",
"indicator_1":"44-65",
"barcode_1":"01000010110011111001",
"container_extent":"23",
"container_extent_type":"sheets"}},
{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"maps",
"container":{ "jsonmodel_type":"container",
"container_locations":[],
"type_1":"box",
"indicator_1":"6208-0841-17-802",
"barcode_1":"11011110101101110100",
"container_extent":"38",
"container_extent_type":"gigabytes"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>88</emph>",
"id_0":"CXNYY",
"level":"collection",
"language":"kal",
"finding_aid_description_rules":"cco",
"finding_aid_date":"HUXC514",
"finding_aid_language":"719434Y792D",
"ead_location":"Y188RLF"}' \
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
  -d '"DFSCK"' \
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


   
    <a href='#jsonmodel-archival_record_children'>JSONModel(:archival_record_children)</a> -- request body -- The children to add to the resource
    

  
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
  -d '"I658FRA"' \
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
    

   
    <a href='#jsonmodel-advanced_query'>JSONModel(:advanced_query)</a> aq -- A json string containing the advanced query
    

  
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


## POST /repositories/:repo_id/top_containers 

__Description__

Create a top container

__Parameters__


   
    <a href='#jsonmodel-top_container'>JSONModel(:top_container)</a> -- request body -- The record to create
    

  
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
"indicator":"W140K893703",
"type":"reel",
"barcode":"YTYYY",
"ils_holding_id":"NWDNA",
"ils_item_id":"LFFOM",
"exported_to_ils":"2016-08-02T12:18:44+02:00"}' \
  "http://localhost:8089//repositories/:repo_id/top_containers"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers"
  

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


## POST /repositories/:repo_id/top_containers/:id 

__Description__

Update a top container

__Parameters__


  
    Integer id -- The ID of the record
    

   
    <a href='#jsonmodel-top_container'>JSONModel(:top_container)</a> -- request body -- The updated record
    

  
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
"indicator":"W140K893703",
"type":"reel",
"barcode":"YTYYY",
"ils_holding_id":"NWDNA",
"ils_item_id":"LFFOM",
"exported_to_ils":"2016-08-02T12:18:44+02:00"}' \
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
  -d '"809353XQY"' \
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
  -d '"KUT67C"' \
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
  -d '"SLRJC"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/location"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/batch/location"
  

```


## POST /repositories/:repo_id/top_containers/bulk/barcodes 

__Description__

Bulk update barcodes

__Parameters__


  
    String -- request body -- JSON string containing barcode data {uri=>barcode}
    

  
    Integer repo_id -- The Repository ID -- The Repository must exist
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"XO371N860"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/barcodes"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089//repositories/:repo_id/top_containers/bulk/barcodes"
  

```


## POST /repositories/:repo_id/top_containers/bulk/locations 

__Description__

Bulk update locations

__Parameters__


  
    String -- request body -- JSON string containing location data {container_uri=>location_uri}
    

  
    Integer repo_id -- The Repository ID -- The Repository must exist
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"NN549O955"' \
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
    

   
    <a href='#jsonmodel-advanced_query'>JSONModel(:advanced_query)</a> aq -- A json string containing the advanced query
    

  
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
  -d '"MQ994401D"' \
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


   
    <a href='#jsonmodel-repository_with_agent'>JSONModel(:repository_with_agent)</a> -- request body -- The record to create
    

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	403 -- access_denied


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/with_agent"
  

```


## POST /repositories/with_agent/:id 

__Description__

Update a repository with an agent representation

__Parameters__


  
    Integer id -- The ID of the record
    

   
    <a href='#jsonmodel-repository_with_agent'>JSONModel(:repository_with_agent)</a> -- request body -- The updated record
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089//repositories/with_agent/1"
  

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
    

   
    <a href='#jsonmodel-advanced_query'>JSONModel(:advanced_query)</a> aq -- A json string containing the advanced query
    

  
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
    

   
    <a href='#jsonmodel-advanced_query'>JSONModel(:advanced_query)</a> aq -- A json string containing the advanced query
    

  
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
    

   
    <a href='#jsonmodel-advanced_query'>JSONModel(:advanced_query)</a> aq -- A json string containing the advanced query
    

  
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
    

   
    <a href='#jsonmodel-advanced_query'>JSONModel(:advanced_query)</a> aq -- A json string containing the advanced query
    

  
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


   
    <a href='#jsonmodel-subject'>JSONModel(:subject)</a> -- request body -- The record to create
    

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"subject",
"external_ids":[],
"publish":true,
"terms":[{ "jsonmodel_type":"term",
"term":"Term 132",
"term_type":"temporal",
"vocabulary":"/vocabularies/156"}],
"external_documents":[],
"vocabulary":"/vocabularies/157",
"authority_id":"http://www.example-476.com",
"scope_note":"F735M288W",
"source":"local"}' \
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
    

   
    <a href='#jsonmodel-subject'>JSONModel(:subject)</a> -- request body -- The updated record
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"subject",
"external_ids":[],
"publish":true,
"terms":[{ "jsonmodel_type":"term",
"term":"Term 132",
"term_type":"temporal",
"vocabulary":"/vocabularies/156"}],
"external_documents":[],
"vocabulary":"/vocabularies/157",
"authority_id":"http://www.example-476.com",
"scope_note":"F735M288W",
"source":"local"}' \
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


   
    <a href='#jsonmodel-active_edits'>JSONModel(:active_edits)</a> -- request body -- The list of active edits
    

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
    

   
    <a href='#jsonmodel-user'>JSONModel(:user)</a> -- request body -- The record to create
    

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}


```shell 
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"N249SOD"' \
  "http://localhost:8089//users"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"RMHLO"' \
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
    

  
    [String] groups -- Array of groups URIs to assign the user to
    

  
    RESTHelpers::BooleanParam remove_groups -- Remove all groups from the user for the current repo_id if true
    

  
    Integer repo_id -- The Repository groups to clear
    

   
    <a href='#jsonmodel-user'>JSONModel(:user)</a> -- request body -- The updated record
    

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}


```shell 
    
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"XUS218T"' \
  "http://localhost:8089//users/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"WR12931L"' \
  "http://localhost:8089//users/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089//users/1"
    
     
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
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
  -d '"90Q273T282"' \
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


   
    <a href='#jsonmodel-vocabulary'>JSONModel(:vocabulary)</a> -- request body -- The record to create
    

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
    

   
    <a href='#jsonmodel-vocabulary'>JSONModel(:vocabulary)</a> -- request body -- The updated record
    

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


# Schemata


##JSONModel(:abstract_agent)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "title": {
      "type": "string",
      "readonly": true
    },
    "is_linked_to_published_record": {
      "type": "boolean",
      "readonly": true
    },
    "agent_type": {
      "type": "string",
      "required": false,
      "enum": [
        "agent_person",
        "agent_corporate_entity",
        "agent_software",
        "agent_family",
        "user"
      ]
    },
    "agent_contacts": {
      "type": "array",
      "items": {
        "type": "JSONModel(:agent_contact) object"
      }
    },
    "linked_agent_roles": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "readonly": true
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "system_generated": {
      "readonly": true,
      "type": "boolean"
    },
    "notes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_bioghist) object"
          }
        ]
      }
    },
    "dates_of_existence": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "publish": {
      "type": "boolean"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | readonly | enum | items | ifmissing | subtype  
 ----- | ---- | -------- | -------- | ---- | ----- | --------- | ------- |  
 uri | string |  |  |  |  |  |  
 title | string |  | true |  |  |  |  
 is_linked_to_published_record | boolean |  | true |  |  |  |  
 agent_type | string |  |  | agent_person | agent_corporate_entity | agent_software | agent_family | user |  |  |  
 agent_contacts | array |  |  |  | {"type"=>"JSONModel(:agent_contact) object"} |  |  
 linked_agent_roles | array |  | true |  | {"type"=>"string"} |  |  
 external_documents | array |  |  |  | {"type"=>"JSONModel(:external_document) object"} |  |  
 rights_statements | array |  |  |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  
 system_generated | boolean |  | true |  |  |  |  
 notes | array |  |  |  | {"type"=>[{"type"=>"JSONModel(:note_bioghist) object"}]} |  |  
 dates_of_existence | array |  |  |  | {"type"=>"JSONModel(:date) object"} |  |  
 publish | boolean |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  
 created_by | string |  | true |  |  |  |  
 last_modified_by | string |  | true |  |  |  |  
 user_mtime | date-time |  | true |  |  |  |  
 system_mtime | date-time |  | true |  |  |  |  
 create_time | date-time |  | true |  |  |  |  
 repository | object |  | true |  |  |  | ref 




##JSONModel(:abstract_agent_relationship)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "subtype": "ref",
  "properties": {
    "description": {
      "type": "string",
      "maxLength": 65000
    },
    "dates": {
      "type": "JSONModel(:date) object"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- |  
 description | string | 65000 |  |  |  |  
 dates | JSONModel(:date) object |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:abstract_archival_object)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 16384,
      "ifmissing": "error"
    },
    "language": {
      "type": "string",
      "dynamic_enum": "language_iso639_2"
    },
    "publish": {
      "type": "boolean"
    },
    "subjects": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:subject) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "linked_events": {
      "type": "array",
      "readonly": "true",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:event) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "extents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:extent) object"
      }
    },
    "dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "linked_agents": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "role": {
            "type": "string",
            "dynamic_enum": "linked_agent_role",
            "ifmissing": "error"
          },
          "terms": {
            "type": "array",
            "items": {
              "type": "JSONModel(:term) uri_or_object"
            }
          },
          "relator": {
            "type": "string",
            "dynamic_enum": "linked_agent_archival_record_relators"
          },
          "title": {
            "type": "string"
          },
          "ref": {
            "type": [
              {
                "type": "JSONModel(:agent_corporate_entity) uri"
              },
              {
                "type": "JSONModel(:agent_family) uri"
              },
              {
                "type": "JSONModel(:agent_person) uri"
              },
              {
                "type": "JSONModel(:agent_software) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "suppressed": {
      "type": "boolean",
      "readonly": "true"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | items | minLength | maxLength | ifmissing | dynamic_enum | readonly | subtype  
 ----- | ---- | -------- | ----- | --------- | --------- | --------- | ------------ | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 external_ids | array |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  |  
 title | string |  |  | 1 | 16384 | error |  |  |  
 language | string |  |  |  |  |  | language_iso639_2 |  |  
 publish | boolean |  |  |  |  |  |  |  |  
 subjects | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:subject) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  
 linked_events | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:event) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  | true |  
 extents | array |  | {"type"=>"JSONModel(:extent) object"} |  |  |  |  |  |  
 dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  
 external_documents | array |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  |  |  |  
 rights_statements | array |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  |  |  |  
 linked_agents | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"role"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_role", "ifmissing"=>"error"}, "terms"=>{"type"=>"array", "items"=>{"type"=>"JSONModel(:term) uri_or_object"}}, "relator"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_archival_record_relators"}, "title"=>{"type"=>"string"}, "ref"=>{"type"=>[{"type"=>"JSONModel(:agent_corporate_entity) uri"}, {"type"=>"JSONModel(:agent_family) uri"}, {"type"=>"JSONModel(:agent_person) uri"}, {"type"=>"JSONModel(:agent_software) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  
 suppressed | boolean |  |  |  |  |  |  | true |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 




##JSONModel(:abstract_classification)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "identifier": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 16384,
      "ifmissing": "error"
    },
    "description": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean",
      "default": true,
      "readonly": true
    },
    "path_from_root": {
      "type": "array",
      "readonly": true,
      "items": {
        "type": "object",
        "properties": {
          "identifier": {
            "type": "string",
            "maxLength": 255,
            "ifmissing": "error"
          },
          "title": {
            "type": "string",
            "minLength": 1,
            "maxLength": 16384,
            "ifmissing": "error"
          }
        }
      }
    },
    "linked_records": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              {
                "type": "JSONModel(:accession) uri"
              },
              {
                "type": "JSONModel(:resource) uri"
              }
            ]
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "creator": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": [
            {
              "type": "JSONModel(:agent_corporate_entity) uri"
            },
            {
              "type": "JSONModel(:agent_family) uri"
            },
            {
              "type": "JSONModel(:agent_person) uri"
            },
            {
              "type": "JSONModel(:agent_software) uri"
            }
          ],
          "ifmissing": "error"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | minLength | default | readonly | items | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ------- | -------- | ----- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 identifier | string |  | 255 | error |  |  |  |  |  
 title | string |  | 16384 | error | 1 |  |  |  |  
 description | string |  | 65000 |  |  |  |  |  |  
 publish | boolean |  |  |  |  | true | true |  |  
 path_from_root | array |  |  |  |  |  | true | {"type"=>"object", "properties"=>{"identifier"=>{"type"=>"string", "maxLength"=>255, "ifmissing"=>"error"}, "title"=>{"type"=>"string", "minLength"=>1, "maxLength"=>16384, "ifmissing"=>"error"}}} |  
 linked_records | array |  |  |  |  |  |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>[{"type"=>"JSONModel(:accession) uri"}, {"type"=>"JSONModel(:resource) uri"}]}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  
 creator | object |  |  |  |  |  |  |  | ref 
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  |  
 last_modified_by | string |  |  |  |  |  | true |  |  
 user_mtime | date-time |  |  |  |  |  | true |  |  
 system_mtime | date-time |  |  |  |  |  | true |  |  
 create_time | date-time |  |  |  |  |  | true |  |  
 repository | object |  |  |  |  |  | true |  | ref 




##JSONModel(:abstract_name)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "authority_id": {
      "type": "string",
      "maxLength": 255
    },
    "dates": {
      "type": "string",
      "maxLength": 255
    },
    "use_dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "qualifier": {
      "type": "string",
      "maxLength": 255
    },
    "source": {
      "type": "string",
      "dynamic_enum": "name_source"
    },
    "rules": {
      "type": "string",
      "dynamic_enum": "name_rule"
    },
    "authorized": {
      "type": "boolean",
      "default": false
    },
    "is_display_name": {
      "type": "boolean",
      "default": false
    },
    "sort_name": {
      "type": "string",
      "maxLength": 255
    },
    "sort_name_auto_generate": {
      "type": "boolean",
      "default": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | items | dynamic_enum | default | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | ----- | ------------ | ------- | -------- | --------- | -------- | ------- |  
 authority_id | string | 255 |  |  |  |  |  |  |  
 dates | string | 255 |  |  |  |  |  |  |  
 use_dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  
 qualifier | string | 255 |  |  |  |  |  |  |  
 source | string |  |  | name_source |  |  |  |  |  
 rules | string |  |  | name_rule |  |  |  |  |  
 authorized | boolean |  |  |  |  |  |  |  |  
 is_display_name | boolean |  |  |  |  |  |  |  |  
 sort_name | string | 255 |  |  |  |  |  |  |  
 sort_name_auto_generate | boolean |  |  |  | true |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 




##JSONModel(:abstract_note)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "label": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean"
    },
    "persistent_id": {
      "type": "string",
      "maxLength": 255
    },
    "ingest_problem": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- |  
 label | string | 65000 |  |  |  |  
 publish | boolean |  |  |  |  |  
 persistent_id | string | 255 |  |  |  |  
 ingest_problem | string | 65000 |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:accession)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/accessions",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "title": {
      "type": "string",
      "maxLength": 8192,
      "ifmissing": null
    },
    "display_string": {
      "type": "string",
      "maxLength": 8192,
      "readonly": true
    },
    "id_0": {
      "type": "string",
      "ifmissing": "error",
      "maxLength": 255
    },
    "id_1": {
      "type": "string",
      "maxLength": 255
    },
    "id_2": {
      "type": "string",
      "maxLength": 255
    },
    "id_3": {
      "type": "string",
      "maxLength": 255
    },
    "content_description": {
      "type": "string",
      "maxLength": 65000
    },
    "condition_description": {
      "type": "string",
      "maxLength": 65000
    },
    "disposition": {
      "type": "string",
      "maxLength": 65000
    },
    "inventory": {
      "type": "string",
      "maxLength": 65000
    },
    "provenance": {
      "type": "string",
      "maxLength": 65000
    },
    "related_accessions": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:accession_parts_relationship) object"
          },
          {
            "type": "JSONModel(:accession_sibling_relationship) object"
          }
        ]
      }
    },
    "accession_date": {
      "type": "date",
      "minLength": 1,
      "ifmissing": "error"
    },
    "publish": {
      "type": "boolean"
    },
    "classifications": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              {
                "type": "JSONModel(:classification) uri"
              },
              {
                "type": "JSONModel(:classification_term) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "subjects": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:subject) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "linked_events": {
      "type": "array",
      "readonly": "true",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:event) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "extents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:extent) object"
      }
    },
    "dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "deaccessions": {
      "type": "array",
      "items": {
        "type": "JSONModel(:deaccession) object"
      }
    },
    "collection_management": {
      "type": "JSONModel(:collection_management) object"
    },
    "user_defined": {
      "type": "JSONModel(:user_defined) object"
    },
    "related_resources": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              {
                "type": "JSONModel(:resource) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "suppressed": {
      "type": "boolean",
      "readonly": "true"
    },
    "acquisition_type": {
      "type": "string",
      "dynamic_enum": "accession_acquisition_type"
    },
    "resource_type": {
      "type": "string",
      "dynamic_enum": "accession_resource_type"
    },
    "restrictions_apply": {
      "type": "boolean",
      "default": false
    },
    "retention_rule": {
      "type": "string",
      "maxLength": 65000
    },
    "general_note": {
      "type": "string",
      "maxLength": 65000
    },
    "access_restrictions": {
      "type": "boolean",
      "default": false
    },
    "access_restrictions_note": {
      "type": "string",
      "maxLength": 65000
    },
    "use_restrictions": {
      "type": "boolean",
      "default": false
    },
    "use_restrictions_note": {
      "type": "string",
      "maxLength": 65000
    },
    "linked_agents": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "role": {
            "type": "string",
            "dynamic_enum": "linked_agent_role",
            "ifmissing": "error"
          },
          "terms": {
            "type": "array",
            "items": {
              "type": "JSONModel(:term) uri_or_object"
            }
          },
          "title": {
            "type": "string"
          },
          "relator": {
            "type": "string",
            "dynamic_enum": "linked_agent_archival_record_relators"
          },
          "ref": {
            "type": [
              {
                "type": "JSONModel(:agent_corporate_entity) uri"
              },
              {
                "type": "JSONModel(:agent_family) uri"
              },
              {
                "type": "JSONModel(:agent_person) uri"
              },
              {
                "type": "JSONModel(:agent_software) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "instances": {
      "type": "array",
      "items": {
        "type": "JSONModel(:instance) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "accession_check_identifier"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | items | maxLength | ifmissing | readonly | minLength | dynamic_enum | default | subtype  
 ----- | ---- | -------- | ----- | --------- | --------- | -------- | --------- | ------------ | ------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  |  
 external_ids | array |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  |  |  
 title | string |  |  | 8192 |  |  |  |  |  |  
 display_string | string |  |  | 8192 |  | true |  |  |  |  
 id_0 | string |  |  | 255 | error |  |  |  |  |  
 id_1 | string |  |  | 255 |  |  |  |  |  |  
 id_2 | string |  |  | 255 |  |  |  |  |  |  
 id_3 | string |  |  | 255 |  |  |  |  |  |  
 content_description | string |  |  | 65000 |  |  |  |  |  |  
 condition_description | string |  |  | 65000 |  |  |  |  |  |  
 disposition | string |  |  | 65000 |  |  |  |  |  |  
 inventory | string |  |  | 65000 |  |  |  |  |  |  
 provenance | string |  |  | 65000 |  |  |  |  |  |  
 related_accessions | array |  | {"type"=>[{"type"=>"JSONModel(:accession_parts_relationship) object"}, {"type"=>"JSONModel(:accession_sibling_relationship) object"}]} |  |  |  |  |  |  |  
 accession_date | date |  |  |  | error |  | 1 |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  |  
 classifications | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>[{"type"=>"JSONModel(:classification) uri"}, {"type"=>"JSONModel(:classification_term) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  
 subjects | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:subject) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  
 linked_events | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:event) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  | true |  |  |  |  
 extents | array |  | {"type"=>"JSONModel(:extent) object"} |  |  |  |  |  |  |  
 dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  |  
 external_documents | array |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  |  |  |  |  
 rights_statements | array |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  |  |  |  |  
 deaccessions | array |  | {"type"=>"JSONModel(:deaccession) object"} |  |  |  |  |  |  |  
 collection_management | JSONModel(:collection_management) object |  |  |  |  |  |  |  |  |  
 user_defined | JSONModel(:user_defined) object |  |  |  |  |  |  |  |  |  
 related_resources | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>[{"type"=>"JSONModel(:resource) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  
 suppressed | boolean |  |  |  |  | true |  |  |  |  
 acquisition_type | string |  |  |  |  |  |  | accession_acquisition_type |  |  
 resource_type | string |  |  |  |  |  |  | accession_resource_type |  |  
 restrictions_apply | boolean |  |  |  |  |  |  |  |  |  
 retention_rule | string |  |  | 65000 |  |  |  |  |  |  
 general_note | string |  |  | 65000 |  |  |  |  |  |  
 access_restrictions | boolean |  |  |  |  |  |  |  |  |  
 access_restrictions_note | string |  |  | 65000 |  |  |  |  |  |  
 use_restrictions | boolean |  |  |  |  |  |  |  |  |  
 use_restrictions_note | string |  |  | 65000 |  |  |  |  |  |  
 linked_agents | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"role"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_role", "ifmissing"=>"error"}, "terms"=>{"type"=>"array", "items"=>{"type"=>"JSONModel(:term) uri_or_object"}}, "title"=>{"type"=>"string"}, "relator"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_archival_record_relators"}, "ref"=>{"type"=>[{"type"=>"JSONModel(:agent_corporate_entity) uri"}, {"type"=>"JSONModel(:agent_family) uri"}, {"type"=>"JSONModel(:agent_person) uri"}, {"type"=>"JSONModel(:agent_software) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  
 instances | array |  | {"type"=>"JSONModel(:instance) object"} |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  | error |  |  |  |  |  
 created_by | string |  |  |  |  | true |  |  |  |  
 last_modified_by | string |  |  |  |  | true |  |  |  |  
 user_mtime | date-time |  |  |  |  | true |  |  |  |  
 system_mtime | date-time |  |  |  |  | true |  |  |  |  
 create_time | date-time |  |  |  |  | true |  |  |  |  
 repository | object |  |  |  |  | true |  |  |  | ref 




##JSONModel(:accession_parts_relationship)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "subtype": "ref",
  "properties": {
    "relator": {
      "type": "string",
      "dynamic_enum": "accession_parts_relator",
      "ifmissing": "error"
    },
    "relator_type": {
      "type": "string",
      "dynamic_enum": "accession_parts_relator_type",
      "ifmissing": "error"
    },
    "ref": {
      "type": "JSONModel(:accession) uri",
      "ifmissing": "error"
    },
    "_resolved": {
      "type": "object",
      "readonly": "true"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | dynamic_enum | ifmissing | readonly | required | subtype  
 ----- | ---- | ------------ | --------- | -------- | -------- | ------- |  
 relator | string | accession_parts_relator | error |  |  |  
 relator_type | string | accession_parts_relator_type | error |  |  |  
 ref | JSONModel(:accession) uri |  | error |  |  |  
 _resolved | object |  |  | true |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  
 created_by | string |  |  | true |  |  
 last_modified_by | string |  |  | true |  |  
 user_mtime | date-time |  |  | true |  |  
 system_mtime | date-time |  |  | true |  |  
 create_time | date-time |  |  | true |  |  
 repository | object |  |  | true |  | ref 




##JSONModel(:accession_sibling_relationship)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "subtype": "ref",
  "properties": {
    "relator": {
      "type": "string",
      "dynamic_enum": "accession_sibling_relator",
      "ifmissing": "error"
    },
    "relator_type": {
      "type": "string",
      "dynamic_enum": "accession_sibling_relator_type",
      "ifmissing": "error"
    },
    "ref": {
      "type": "JSONModel(:accession) uri",
      "ifmissing": "error"
    },
    "_resolved": {
      "type": "object",
      "readonly": "true"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | dynamic_enum | ifmissing | readonly | required | subtype  
 ----- | ---- | ------------ | --------- | -------- | -------- | ------- |  
 relator | string | accession_sibling_relator | error |  |  |  
 relator_type | string | accession_sibling_relator_type | error |  |  |  
 ref | JSONModel(:accession) uri |  | error |  |  |  
 _resolved | object |  |  | true |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  
 created_by | string |  |  | true |  |  
 last_modified_by | string |  |  | true |  |  
 user_mtime | date-time |  |  | true |  |  
 system_mtime | date-time |  |  | true |  |  
 create_time | date-time |  |  | true |  |  
 repository | object |  |  | true |  | ref 




##JSONModel(:active_edits)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "uri": "/update_monitor",
  "type": "object",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "active_edits": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "user": {
            "type": "string",
            "maxLength": 255,
            "ifmissing": "error"
          },
          "uri": {
            "type": "string",
            "maxLength": 255,
            "ifmissing": "error"
          },
          "time": {
            "type": "string",
            "maxLength": 255,
            "ifmissing": "error"
          }
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | items | ifmissing | readonly | subtype  
 ----- | ---- | -------- | ----- | --------- | -------- | ------- |  
 uri | string |  |  |  |  |  
 active_edits | array |  | {"type"=>"object", "properties"=>{"user"=>{"type"=>"string", "maxLength"=>255, "ifmissing"=>"error"}, "uri"=>{"type"=>"string", "maxLength"=>255, "ifmissing"=>"error"}, "time"=>{"type"=>"string", "maxLength"=>255, "ifmissing"=>"error"}}} |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:advanced_query)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "query": {
      "type": [
        "JSONModel(:boolean_query) object",
        "JSONModel(:field_query) object",
        "JSONModel(:date_field_query) object",
        "JSONModel(:boolean_field_query) object"
      ]
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | readonly | subtype  
 ----- | ---- | -------- | --------- | -------- | ------- |  
 query | JSONModel(:boolean_query) object | JSONModel(:field_query) object | JSONModel(:date_field_query) object | JSONModel(:boolean_field_query) object |  |  |  |  
 lock_version | integer | string |  |  |  |  
 jsonmodel_type | string |  | error |  |  
 created_by | string |  |  | true |  
 last_modified_by | string |  |  | true |  
 user_mtime | date-time |  |  | true |  
 system_mtime | date-time |  |  | true |  
 create_time | date-time |  |  | true |  
 repository | object |  |  | true | ref 




##JSONModel(:agent_contact)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "maxLength": 65000,
      "ifmissing": "error"
    },
    "salutation": {
      "type": "string",
      "dynamic_enum": "agent_contact_salutation"
    },
    "address_1": {
      "type": "string",
      "maxLength": 65000
    },
    "address_2": {
      "type": "string",
      "maxLength": 65000
    },
    "address_3": {
      "type": "string",
      "maxLength": 65000
    },
    "city": {
      "type": "string",
      "maxLength": 65000
    },
    "region": {
      "type": "string",
      "maxLength": 65000
    },
    "country": {
      "type": "string",
      "maxLength": 65000
    },
    "post_code": {
      "type": "string",
      "maxLength": 65000
    },
    "telephones": {
      "type": "array",
      "items": {
        "type": "JSONModel(:telephone) object"
      }
    },
    "fax": {
      "type": "string",
      "maxLength": 65000
    },
    "email": {
      "type": "string",
      "maxLength": 65000
    },
    "email_signature": {
      "type": "string",
      "maxLength": 65000
    },
    "note": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | ifmissing | dynamic_enum | items | required | readonly | subtype  
 ----- | ---- | --------- | --------- | ------------ | ----- | -------- | -------- | ------- |  
 name | string | 65000 | error |  |  |  |  |  
 salutation | string |  |  | agent_contact_salutation |  |  |  |  
 address_1 | string | 65000 |  |  |  |  |  |  
 address_2 | string | 65000 |  |  |  |  |  |  
 address_3 | string | 65000 |  |  |  |  |  |  
 city | string | 65000 |  |  |  |  |  |  
 region | string | 65000 |  |  |  |  |  |  
 country | string | 65000 |  |  |  |  |  |  
 post_code | string | 65000 |  |  |  |  |  |  
 telephones | array |  |  |  | {"type"=>"JSONModel(:telephone) object"} |  |  |  
 fax | string | 65000 |  |  |  |  |  |  
 email | string | 65000 |  |  |  |  |  |  
 email_signature | string | 65000 |  |  |  |  |  |  
 note | string | 65000 |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  | true | ref 




##JSONModel(:agent_corporate_entity)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_agent",
  "uri": "/agents/corporate_entities",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "title": {
      "type": "string",
      "readonly": true
    },
    "is_linked_to_published_record": {
      "type": "boolean",
      "readonly": true
    },
    "agent_type": {
      "type": "string",
      "required": false,
      "enum": [
        "agent_person",
        "agent_corporate_entity",
        "agent_software",
        "agent_family",
        "user"
      ]
    },
    "agent_contacts": {
      "type": "array",
      "items": {
        "type": "JSONModel(:agent_contact) object"
      }
    },
    "linked_agent_roles": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "readonly": true
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "system_generated": {
      "readonly": true,
      "type": "boolean"
    },
    "notes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_bioghist) object"
          }
        ]
      }
    },
    "dates_of_existence": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "publish": {
      "type": "boolean"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "names": {
      "type": "array",
      "items": {
        "type": "JSONModel(:name_corporate_entity) object"
      },
      "ifmissing": "error",
      "minItems": 1
    },
    "display_name": {
      "type": "JSONModel(:name_corporate_entity) object",
      "readonly": true
    },
    "related_agents": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:agent_relationship_subordinatesuperior) object"
          },
          {
            "type": "JSONModel(:agent_relationship_earlierlater) object"
          },
          {
            "type": "JSONModel(:agent_relationship_associative) object"
          }
        ]
      }
    }
  },
  "validations": [
    [
      "error",
      "check_agent_corporate_entity"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | readonly | enum | items | ifmissing | subtype | minItems  
 ----- | ---- | -------- | -------- | ---- | ----- | --------- | ------- | -------- |  
 uri | string |  |  |  |  |  |  |  
 title | string |  | true |  |  |  |  |  
 is_linked_to_published_record | boolean |  | true |  |  |  |  |  
 agent_type | string |  |  | agent_person | agent_corporate_entity | agent_software | agent_family | user |  |  |  |  
 agent_contacts | array |  |  |  | {"type"=>"JSONModel(:agent_contact) object"} |  |  |  
 linked_agent_roles | array |  | true |  | {"type"=>"string"} |  |  |  
 external_documents | array |  |  |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  
 rights_statements | array |  |  |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  
 system_generated | boolean |  | true |  |  |  |  |  
 notes | array |  |  |  | {"type"=>[{"type"=>"JSONModel(:note_bioghist) object"}]} |  |  |  
 dates_of_existence | array |  |  |  | {"type"=>"JSONModel(:date) object"} |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  
 created_by | string |  | true |  |  |  |  |  
 last_modified_by | string |  | true |  |  |  |  |  
 user_mtime | date-time |  | true |  |  |  |  |  
 system_mtime | date-time |  | true |  |  |  |  |  
 create_time | date-time |  | true |  |  |  |  |  
 repository | object |  | true |  |  |  | ref |  
 names | array |  |  |  | {"type"=>"JSONModel(:name_corporate_entity) object"} | error |  | 1 
 display_name | JSONModel(:name_corporate_entity) object |  | true |  |  |  |  |  
 related_agents | array |  |  |  | {"type"=>[{"type"=>"JSONModel(:agent_relationship_subordinatesuperior) object"}, {"type"=>"JSONModel(:agent_relationship_earlierlater) object"}, {"type"=>"JSONModel(:agent_relationship_associative) object"}]} |  |  |  




##JSONModel(:agent_family)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_agent",
  "uri": "/agents/families",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "title": {
      "type": "string",
      "readonly": true
    },
    "is_linked_to_published_record": {
      "type": "boolean",
      "readonly": true
    },
    "agent_type": {
      "type": "string",
      "required": false,
      "enum": [
        "agent_person",
        "agent_corporate_entity",
        "agent_software",
        "agent_family",
        "user"
      ]
    },
    "agent_contacts": {
      "type": "array",
      "items": {
        "type": "JSONModel(:agent_contact) object"
      }
    },
    "linked_agent_roles": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "readonly": true
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "system_generated": {
      "readonly": true,
      "type": "boolean"
    },
    "notes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_bioghist) object"
          }
        ]
      }
    },
    "dates_of_existence": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "publish": {
      "type": "boolean"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "names": {
      "type": "array",
      "items": {
        "type": "JSONModel(:name_family) object"
      },
      "ifmissing": "error",
      "minItems": 1
    },
    "display_name": {
      "type": "JSONModel(:name_family) object",
      "readonly": true
    },
    "related_agents": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:agent_relationship_earlierlater) object"
          },
          {
            "type": "JSONModel(:agent_relationship_associative) object"
          }
        ]
      }
    }
  },
  "validations": [
    [
      "error",
      "check_agent_family"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | readonly | enum | items | ifmissing | subtype | minItems  
 ----- | ---- | -------- | -------- | ---- | ----- | --------- | ------- | -------- |  
 uri | string |  |  |  |  |  |  |  
 title | string |  | true |  |  |  |  |  
 is_linked_to_published_record | boolean |  | true |  |  |  |  |  
 agent_type | string |  |  | agent_person | agent_corporate_entity | agent_software | agent_family | user |  |  |  |  
 agent_contacts | array |  |  |  | {"type"=>"JSONModel(:agent_contact) object"} |  |  |  
 linked_agent_roles | array |  | true |  | {"type"=>"string"} |  |  |  
 external_documents | array |  |  |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  
 rights_statements | array |  |  |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  
 system_generated | boolean |  | true |  |  |  |  |  
 notes | array |  |  |  | {"type"=>[{"type"=>"JSONModel(:note_bioghist) object"}]} |  |  |  
 dates_of_existence | array |  |  |  | {"type"=>"JSONModel(:date) object"} |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  
 created_by | string |  | true |  |  |  |  |  
 last_modified_by | string |  | true |  |  |  |  |  
 user_mtime | date-time |  | true |  |  |  |  |  
 system_mtime | date-time |  | true |  |  |  |  |  
 create_time | date-time |  | true |  |  |  |  |  
 repository | object |  | true |  |  |  | ref |  
 names | array |  |  |  | {"type"=>"JSONModel(:name_family) object"} | error |  | 1 
 display_name | JSONModel(:name_family) object |  | true |  |  |  |  |  
 related_agents | array |  |  |  | {"type"=>[{"type"=>"JSONModel(:agent_relationship_earlierlater) object"}, {"type"=>"JSONModel(:agent_relationship_associative) object"}]} |  |  |  




##JSONModel(:agent_person)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_agent",
  "uri": "/agents/people",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "title": {
      "type": "string",
      "readonly": true
    },
    "is_linked_to_published_record": {
      "type": "boolean",
      "readonly": true
    },
    "agent_type": {
      "type": "string",
      "required": false,
      "enum": [
        "agent_person",
        "agent_corporate_entity",
        "agent_software",
        "agent_family",
        "user"
      ]
    },
    "agent_contacts": {
      "type": "array",
      "items": {
        "type": "JSONModel(:agent_contact) object"
      }
    },
    "linked_agent_roles": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "readonly": true
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "system_generated": {
      "readonly": true,
      "type": "boolean"
    },
    "notes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_bioghist) object"
          }
        ]
      }
    },
    "dates_of_existence": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "publish": {
      "type": "boolean"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "names": {
      "type": "array",
      "items": {
        "type": "JSONModel(:name_person) object"
      },
      "ifmissing": "error",
      "minItems": 1
    },
    "display_name": {
      "type": "JSONModel(:name_person) object",
      "readonly": true
    },
    "related_agents": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:agent_relationship_parentchild) object"
          },
          {
            "type": "JSONModel(:agent_relationship_earlierlater) object"
          },
          {
            "type": "JSONModel(:agent_relationship_associative) object"
          }
        ]
      }
    }
  },
  "validations": [
    [
      "error",
      "check_agent_person"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | readonly | enum | items | ifmissing | subtype | minItems  
 ----- | ---- | -------- | -------- | ---- | ----- | --------- | ------- | -------- |  
 uri | string |  |  |  |  |  |  |  
 title | string |  | true |  |  |  |  |  
 is_linked_to_published_record | boolean |  | true |  |  |  |  |  
 agent_type | string |  |  | agent_person | agent_corporate_entity | agent_software | agent_family | user |  |  |  |  
 agent_contacts | array |  |  |  | {"type"=>"JSONModel(:agent_contact) object"} |  |  |  
 linked_agent_roles | array |  | true |  | {"type"=>"string"} |  |  |  
 external_documents | array |  |  |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  
 rights_statements | array |  |  |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  
 system_generated | boolean |  | true |  |  |  |  |  
 notes | array |  |  |  | {"type"=>[{"type"=>"JSONModel(:note_bioghist) object"}]} |  |  |  
 dates_of_existence | array |  |  |  | {"type"=>"JSONModel(:date) object"} |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  
 created_by | string |  | true |  |  |  |  |  
 last_modified_by | string |  | true |  |  |  |  |  
 user_mtime | date-time |  | true |  |  |  |  |  
 system_mtime | date-time |  | true |  |  |  |  |  
 create_time | date-time |  | true |  |  |  |  |  
 repository | object |  | true |  |  |  | ref |  
 names | array |  |  |  | {"type"=>"JSONModel(:name_person) object"} | error |  | 1 
 display_name | JSONModel(:name_person) object |  | true |  |  |  |  |  
 related_agents | array |  |  |  | {"type"=>[{"type"=>"JSONModel(:agent_relationship_parentchild) object"}, {"type"=>"JSONModel(:agent_relationship_earlierlater) object"}, {"type"=>"JSONModel(:agent_relationship_associative) object"}]} |  |  |  




##JSONModel(:agent_relationship_associative)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "subtype": "ref",
  "parent": "abstract_agent_relationship",
  "properties": {
    "description": {
      "type": "string",
      "maxLength": 65000
    },
    "dates": {
      "type": "JSONModel(:date) object"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "relator": {
      "type": "string",
      "dynamic_enum": "agent_relationship_associative_relator",
      "ifmissing": "error"
    },
    "ref": {
      "type": [
        {
          "type": "JSONModel(:agent_person) uri"
        },
        {
          "type": "JSONModel(:agent_family) uri"
        },
        {
          "type": "JSONModel(:agent_corporate_entity) uri"
        }
      ],
      "ifmissing": "error"
    },
    "_resolved": {
      "type": "object",
      "readonly": "true"
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | dynamic_enum  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ------------ |  
 description | string | 65000 |  |  |  |  |  
 dates | JSONModel(:date) object |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  
 created_by | string |  |  |  | true |  |  
 last_modified_by | string |  |  |  | true |  |  
 user_mtime | date-time |  |  |  | true |  |  
 system_mtime | date-time |  |  |  | true |  |  
 create_time | date-time |  |  |  | true |  |  
 repository | object |  |  |  | true | ref |  
 relator | string |  |  | error |  |  | agent_relationship_associative_relator 
 ref | {"type"=>"JSONModel(:agent_person) uri"} | {"type"=>"JSONModel(:agent_family) uri"} | {"type"=>"JSONModel(:agent_corporate_entity) uri"} |  |  | error |  |  |  
 _resolved | object |  |  |  | true |  |  




##JSONModel(:agent_relationship_earlierlater)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_agent_relationship",
  "subtype": "ref",
  "properties": {
    "description": {
      "type": "string",
      "maxLength": 65000
    },
    "dates": {
      "type": "JSONModel(:date) object"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "relator": {
      "type": "string",
      "dynamic_enum": "agent_relationship_earlierlater_relator",
      "ifmissing": "error"
    },
    "ref": {
      "type": [
        {
          "type": "JSONModel(:agent_person) uri"
        },
        {
          "type": "JSONModel(:agent_corporate_entity) uri"
        },
        {
          "type": "JSONModel(:agent_family) uri"
        }
      ],
      "ifmissing": "error"
    },
    "_resolved": {
      "type": "object",
      "readonly": "true"
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | dynamic_enum  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ------------ |  
 description | string | 65000 |  |  |  |  |  
 dates | JSONModel(:date) object |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  
 created_by | string |  |  |  | true |  |  
 last_modified_by | string |  |  |  | true |  |  
 user_mtime | date-time |  |  |  | true |  |  
 system_mtime | date-time |  |  |  | true |  |  
 create_time | date-time |  |  |  | true |  |  
 repository | object |  |  |  | true | ref |  
 relator | string |  |  | error |  |  | agent_relationship_earlierlater_relator 
 ref | {"type"=>"JSONModel(:agent_person) uri"} | {"type"=>"JSONModel(:agent_corporate_entity) uri"} | {"type"=>"JSONModel(:agent_family) uri"} |  |  | error |  |  |  
 _resolved | object |  |  |  | true |  |  




##JSONModel(:agent_relationship_parentchild)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_agent_relationship",
  "subtype": "ref",
  "properties": {
    "description": {
      "type": "string",
      "maxLength": 65000
    },
    "dates": {
      "type": "JSONModel(:date) object"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "relator": {
      "type": "string",
      "dynamic_enum": "agent_relationship_parentchild_relator",
      "ifmissing": "error"
    },
    "ref": {
      "type": [
        {
          "type": "JSONModel(:agent_person) uri"
        }
      ],
      "ifmissing": "error"
    },
    "_resolved": {
      "type": "object",
      "readonly": "true"
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | dynamic_enum  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ------------ |  
 description | string | 65000 |  |  |  |  |  
 dates | JSONModel(:date) object |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  
 created_by | string |  |  |  | true |  |  
 last_modified_by | string |  |  |  | true |  |  
 user_mtime | date-time |  |  |  | true |  |  
 system_mtime | date-time |  |  |  | true |  |  
 create_time | date-time |  |  |  | true |  |  
 repository | object |  |  |  | true | ref |  
 relator | string |  |  | error |  |  | agent_relationship_parentchild_relator 
 ref | {"type"=>"JSONModel(:agent_person) uri"} |  |  | error |  |  |  
 _resolved | object |  |  |  | true |  |  




##JSONModel(:agent_relationship_subordinatesuperior)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_agent_relationship",
  "subtype": "ref",
  "properties": {
    "description": {
      "type": "string",
      "maxLength": 65000
    },
    "dates": {
      "type": "JSONModel(:date) object"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "relator": {
      "type": "string",
      "dynamic_enum": "agent_relationship_subordinatesuperior_relator",
      "ifmissing": "error"
    },
    "ref": {
      "type": [
        {
          "type": "JSONModel(:agent_corporate_entity) uri"
        }
      ],
      "ifmissing": "error"
    },
    "_resolved": {
      "type": "object",
      "readonly": "true"
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | dynamic_enum  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ------------ |  
 description | string | 65000 |  |  |  |  |  
 dates | JSONModel(:date) object |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  
 created_by | string |  |  |  | true |  |  
 last_modified_by | string |  |  |  | true |  |  
 user_mtime | date-time |  |  |  | true |  |  
 system_mtime | date-time |  |  |  | true |  |  
 create_time | date-time |  |  |  | true |  |  
 repository | object |  |  |  | true | ref |  
 relator | string |  |  | error |  |  | agent_relationship_subordinatesuperior_relator 
 ref | {"type"=>"JSONModel(:agent_corporate_entity) uri"} |  |  | error |  |  |  
 _resolved | object |  |  |  | true |  |  




##JSONModel(:agent_software)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_agent",
  "uri": "/agents/software",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "title": {
      "type": "string",
      "readonly": true
    },
    "is_linked_to_published_record": {
      "type": "boolean",
      "readonly": true
    },
    "agent_type": {
      "type": "string",
      "required": false,
      "enum": [
        "agent_person",
        "agent_corporate_entity",
        "agent_software",
        "agent_family",
        "user"
      ]
    },
    "agent_contacts": {
      "type": "array",
      "items": {
        "type": "JSONModel(:agent_contact) object"
      }
    },
    "linked_agent_roles": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "readonly": true
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "system_generated": {
      "readonly": true,
      "type": "boolean"
    },
    "notes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_bioghist) object"
          }
        ]
      }
    },
    "dates_of_existence": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "publish": {
      "type": "boolean"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "display_name": {
      "type": "JSONModel(:name_software) object",
      "readonly": true
    },
    "names": {
      "type": "array",
      "items": {
        "type": "JSONModel(:name_software) object"
      },
      "ifmissing": "error",
      "minItems": 1
    }
  },
  "validations": [
    [
      "error",
      "check_agent_software"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | readonly | enum | items | ifmissing | subtype | minItems  
 ----- | ---- | -------- | -------- | ---- | ----- | --------- | ------- | -------- |  
 uri | string |  |  |  |  |  |  |  
 title | string |  | true |  |  |  |  |  
 is_linked_to_published_record | boolean |  | true |  |  |  |  |  
 agent_type | string |  |  | agent_person | agent_corporate_entity | agent_software | agent_family | user |  |  |  |  
 agent_contacts | array |  |  |  | {"type"=>"JSONModel(:agent_contact) object"} |  |  |  
 linked_agent_roles | array |  | true |  | {"type"=>"string"} |  |  |  
 external_documents | array |  |  |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  
 rights_statements | array |  |  |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  
 system_generated | boolean |  | true |  |  |  |  |  
 notes | array |  |  |  | {"type"=>[{"type"=>"JSONModel(:note_bioghist) object"}]} |  |  |  
 dates_of_existence | array |  |  |  | {"type"=>"JSONModel(:date) object"} |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  
 created_by | string |  | true |  |  |  |  |  
 last_modified_by | string |  | true |  |  |  |  |  
 user_mtime | date-time |  | true |  |  |  |  |  
 system_mtime | date-time |  | true |  |  |  |  |  
 create_time | date-time |  | true |  |  |  |  |  
 repository | object |  | true |  |  |  | ref |  
 display_name | JSONModel(:name_software) object |  | true |  |  |  |  |  
 names | array |  |  |  | {"type"=>"JSONModel(:name_software) object"} | error |  | 1 




##JSONModel(:archival_object)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_archival_object",
  "uri": "/repositories/:repo_id/archival_objects",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 8192,
      "ifmissing": null
    },
    "language": {
      "type": "string",
      "dynamic_enum": "language_iso639_2"
    },
    "publish": {
      "type": "boolean"
    },
    "subjects": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:subject) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "linked_events": {
      "type": "array",
      "readonly": "true",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:event) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "extents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:extent) object"
      }
    },
    "dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "linked_agents": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "role": {
            "type": "string",
            "dynamic_enum": "linked_agent_role",
            "ifmissing": "error"
          },
          "terms": {
            "type": "array",
            "items": {
              "type": "JSONModel(:term) uri_or_object"
            }
          },
          "relator": {
            "type": "string",
            "dynamic_enum": "linked_agent_archival_record_relators"
          },
          "title": {
            "type": "string"
          },
          "ref": {
            "type": [
              {
                "type": "JSONModel(:agent_corporate_entity) uri"
              },
              {
                "type": "JSONModel(:agent_family) uri"
              },
              {
                "type": "JSONModel(:agent_person) uri"
              },
              {
                "type": "JSONModel(:agent_software) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "suppressed": {
      "type": "boolean",
      "readonly": "true"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "ref_id": {
      "type": "string",
      "maxLength": 255,
      "pattern": "\\A[a-zA-Z0-9\\-_:\\.]*\\z"
    },
    "component_id": {
      "type": "string",
      "maxLength": 255,
      "required": false,
      "default": ""
    },
    "level": {
      "type": "string",
      "ifmissing": "error",
      "dynamic_enum": "archival_record_level"
    },
    "other_level": {
      "type": "string",
      "maxLength": 255
    },
    "display_string": {
      "type": "string",
      "maxLength": 8192,
      "readonly": true
    },
    "restrictions_apply": {
      "type": "boolean",
      "default": false
    },
    "repository_processing_note": {
      "type": "string",
      "maxLength": 65000
    },
    "parent": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:archival_object) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "resource": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:resource) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "series": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:archival_object) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "position": {
      "type": "integer",
      "required": false
    },
    "instances": {
      "type": "array",
      "items": {
        "type": "JSONModel(:instance) object"
      }
    },
    "notes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_bibliography) object"
          },
          {
            "type": "JSONModel(:note_index) object"
          },
          {
            "type": "JSONModel(:note_multipart) object"
          },
          {
            "type": "JSONModel(:note_singlepart) object"
          }
        ]
      }
    },
    "has_unpublished_ancestor": {
      "type": "boolean",
      "readonly": "true"
    },
    "representative_image": {
      "type": "JSONModel(:file_version) object",
      "readonly": true
    }
  },
  "validations": [
    [
      "error",
      "archival_object_check_identifier"
    ],
    [
      "error",
      "check_archival_object"
    ],
    [
      "warning",
      "check_archival_object_otherlevel"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | items | minLength | maxLength | ifmissing | dynamic_enum | readonly | subtype | pattern | default  
 ----- | ---- | -------- | ----- | --------- | --------- | --------- | ------------ | -------- | ------- | ------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  |  |  
 external_ids | array |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  |  |  |  
 title | string |  |  | 1 | 8192 |  |  |  |  |  |  
 language | string |  |  |  |  |  | language_iso639_2 |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  |  |  
 subjects | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:subject) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  |  
 linked_events | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:event) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  | true |  |  |  
 extents | array |  | {"type"=>"JSONModel(:extent) object"} |  |  |  |  |  |  |  |  
 dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  |  |  
 external_documents | array |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  |  |  |  |  |  
 rights_statements | array |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  |  |  |  |  |  
 linked_agents | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"role"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_role", "ifmissing"=>"error"}, "terms"=>{"type"=>"array", "items"=>{"type"=>"JSONModel(:term) uri_or_object"}}, "relator"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_archival_record_relators"}, "title"=>{"type"=>"string"}, "ref"=>{"type"=>[{"type"=>"JSONModel(:agent_corporate_entity) uri"}, {"type"=>"JSONModel(:agent_family) uri"}, {"type"=>"JSONModel(:agent_person) uri"}, {"type"=>"JSONModel(:agent_software) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  |  
 suppressed | boolean |  |  |  |  |  |  | true |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  |  |  |  | true |  |  |  
 create_time | date-time |  |  |  |  |  |  | true |  |  |  
 repository | object |  |  |  |  |  |  | true | ref |  |  
 ref_id | string |  |  |  | 255 |  |  |  |  | \A[a-zA-Z0-9\-_:\.]*\z |  
 component_id | string |  |  |  | 255 |  |  |  |  |  |  
 level | string |  |  |  |  | error | archival_record_level |  |  |  |  
 other_level | string |  |  |  | 255 |  |  |  |  |  |  
 display_string | string |  |  |  | 8192 |  |  | true |  |  |  
 restrictions_apply | boolean |  |  |  |  |  |  |  |  |  |  
 repository_processing_note | string |  |  |  | 65000 |  |  |  |  |  |  
 parent | object |  |  |  |  |  |  |  | ref |  |  
 resource | object |  |  |  |  |  |  |  | ref |  |  
 series | object |  |  |  |  |  |  |  | ref |  |  
 position | integer |  |  |  |  |  |  |  |  |  |  
 instances | array |  | {"type"=>"JSONModel(:instance) object"} |  |  |  |  |  |  |  |  
 notes | array |  | {"type"=>[{"type"=>"JSONModel(:note_bibliography) object"}, {"type"=>"JSONModel(:note_index) object"}, {"type"=>"JSONModel(:note_multipart) object"}, {"type"=>"JSONModel(:note_singlepart) object"}]} |  |  |  |  |  |  |  |  
 has_unpublished_ancestor | boolean |  |  |  |  |  |  | true |  |  |  
 representative_image | JSONModel(:file_version) object |  |  |  |  |  |  | true |  |  |  




##JSONModel(:archival_record_children)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "children": {
      "type": "array",
      "items": {
        "type": "JSONModel(:archival_object) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | items | required | ifmissing | readonly | subtype  
 ----- | ---- | ----- | -------- | --------- | -------- | ------- |  
 children | array | {"type"=>"JSONModel(:archival_object) object"} |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:boolean_field_query)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "field": {
      "type": "string",
      "ifmissing": "error"
    },
    "value": {
      "type": "boolean",
      "ifmissing": "error",
      "default": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | ifmissing | default | required | readonly | subtype  
 ----- | ---- | --------- | ------- | -------- | -------- | ------- |  
 field | string | error |  |  |  |  
 value | boolean | error | true |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string | error |  |  |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:boolean_query)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "op": {
      "type": "string",
      "enum": [
        "AND",
        "OR",
        "NOT"
      ],
      "ifmissing": "error"
    },
    "subqueries": {
      "type": [
        "JSONModel(:boolean_query) object",
        "JSONModel(:field_query) object",
        "JSONModel(:boolean_field_query) object",
        "JSONModel(:date_field_query) object"
      ],
      "ifmissing": "error",
      "minItems": 1
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | enum | ifmissing | minItems | required | readonly | subtype  
 ----- | ---- | ---- | --------- | -------- | -------- | -------- | ------- |  
 op | string | AND | OR | NOT | error |  |  |  |  
 subqueries | JSONModel(:boolean_query) object | JSONModel(:field_query) object | JSONModel(:boolean_field_query) object | JSONModel(:date_field_query) object |  | error | 1 |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  
 created_by | string |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  | true |  
 create_time | date-time |  |  |  |  | true |  
 repository | object |  |  |  |  | true | ref 




##JSONModel(:classification)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_classification",
  "uri": "/repositories/:repo_id/classifications",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "identifier": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 16384,
      "ifmissing": "error"
    },
    "description": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean",
      "default": true,
      "readonly": true
    },
    "path_from_root": {
      "type": "array",
      "readonly": true,
      "items": {
        "type": "object",
        "properties": {
          "identifier": {
            "type": "string",
            "maxLength": 255,
            "ifmissing": "error"
          },
          "title": {
            "type": "string",
            "minLength": 1,
            "maxLength": 16384,
            "ifmissing": "error"
          }
        }
      }
    },
    "linked_records": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              {
                "type": "JSONModel(:accession) uri"
              },
              {
                "type": "JSONModel(:resource) uri"
              }
            ]
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "creator": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": [
            {
              "type": "JSONModel(:agent_corporate_entity) uri"
            },
            {
              "type": "JSONModel(:agent_family) uri"
            },
            {
              "type": "JSONModel(:agent_person) uri"
            },
            {
              "type": "JSONModel(:agent_software) uri"
            }
          ],
          "ifmissing": "error"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | minLength | default | readonly | items | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ------- | -------- | ----- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 identifier | string |  | 255 | error |  |  |  |  |  
 title | string |  | 16384 | error | 1 |  |  |  |  
 description | string |  | 65000 |  |  |  |  |  |  
 publish | boolean |  |  |  |  | true | true |  |  
 path_from_root | array |  |  |  |  |  | true | {"type"=>"object", "properties"=>{"identifier"=>{"type"=>"string", "maxLength"=>255, "ifmissing"=>"error"}, "title"=>{"type"=>"string", "minLength"=>1, "maxLength"=>16384, "ifmissing"=>"error"}}} |  
 linked_records | array |  |  |  |  |  |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>[{"type"=>"JSONModel(:accession) uri"}, {"type"=>"JSONModel(:resource) uri"}]}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  
 creator | object |  |  |  |  |  |  |  | ref 
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  |  
 last_modified_by | string |  |  |  |  |  | true |  |  
 user_mtime | date-time |  |  |  |  |  | true |  |  
 system_mtime | date-time |  |  |  |  |  | true |  |  
 create_time | date-time |  |  |  |  |  | true |  |  
 repository | object |  |  |  |  |  | true |  | ref 




##JSONModel(:classification_term)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_classification",
  "uri": "/repositories/:repo_id/classification_terms",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "identifier": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 16384,
      "ifmissing": "error"
    },
    "description": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean",
      "default": true,
      "readonly": true
    },
    "path_from_root": {
      "type": "array",
      "readonly": true,
      "items": {
        "type": "object",
        "properties": {
          "identifier": {
            "type": "string",
            "maxLength": 255,
            "ifmissing": "error"
          },
          "title": {
            "type": "string",
            "minLength": 1,
            "maxLength": 16384,
            "ifmissing": "error"
          }
        }
      }
    },
    "linked_records": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              {
                "type": "JSONModel(:accession) uri"
              },
              {
                "type": "JSONModel(:resource) uri"
              }
            ]
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "creator": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": [
            {
              "type": "JSONModel(:agent_corporate_entity) uri"
            },
            {
              "type": "JSONModel(:agent_family) uri"
            },
            {
              "type": "JSONModel(:agent_person) uri"
            },
            {
              "type": "JSONModel(:agent_software) uri"
            }
          ],
          "ifmissing": "error"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "position": {
      "type": "integer",
      "required": false
    },
    "parent": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:classification_term) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "classification": {
      "type": "object",
      "subtype": "ref",
      "ifmissing": "error",
      "properties": {
        "ref": {
          "type": "JSONModel(:classification) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | minLength | default | readonly | items | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ------- | -------- | ----- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 identifier | string |  | 255 | error |  |  |  |  |  
 title | string |  | 16384 | error | 1 |  |  |  |  
 description | string |  | 65000 |  |  |  |  |  |  
 publish | boolean |  |  |  |  | true | true |  |  
 path_from_root | array |  |  |  |  |  | true | {"type"=>"object", "properties"=>{"identifier"=>{"type"=>"string", "maxLength"=>255, "ifmissing"=>"error"}, "title"=>{"type"=>"string", "minLength"=>1, "maxLength"=>16384, "ifmissing"=>"error"}}} |  
 linked_records | array |  |  |  |  |  |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>[{"type"=>"JSONModel(:accession) uri"}, {"type"=>"JSONModel(:resource) uri"}]}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  
 creator | object |  |  |  |  |  |  |  | ref 
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  |  
 last_modified_by | string |  |  |  |  |  | true |  |  
 user_mtime | date-time |  |  |  |  |  | true |  |  
 system_mtime | date-time |  |  |  |  |  | true |  |  
 create_time | date-time |  |  |  |  |  | true |  |  
 repository | object |  |  |  |  |  | true |  | ref 
 position | integer |  |  |  |  |  |  |  |  
 parent | object |  |  |  |  |  |  |  | ref 
 classification | object |  |  | error |  |  |  |  | ref 




##JSONModel(:record_tree)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "id": {
      "type": "integer",
      "ifmissing": "error"
    },
    "record_uri": {
      "type": "string",
      "ifmissing": "error"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "required": false,
      "maxLength": 16384
    },
    "suppressed": {
      "type": "boolean",
      "default": false
    },
    "publish": {
      "type": "boolean"
    },
    "has_children": {
      "type": "boolean",
      "readonly": true
    },
    "node_type": {
      "type": "string",
      "maxLength": 255
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | minLength | maxLength | default | readonly | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ------- | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  
 id | integer |  | error |  |  |  |  |  
 record_uri | string |  | error |  |  |  |  |  
 title | string |  |  | 1 | 16384 |  |  |  
 suppressed | boolean |  |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 has_children | boolean |  |  |  |  |  | true |  
 node_type | string |  |  |  | 255 |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  | true | ref 




##JSONModel(:classification_tree)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/classifications/:classification_id/tree",
  "parent": "record_tree",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "id": {
      "type": "integer",
      "ifmissing": "error"
    },
    "record_uri": {
      "type": "string",
      "ifmissing": "error"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "required": false,
      "maxLength": 16384
    },
    "suppressed": {
      "type": "boolean",
      "default": false
    },
    "publish": {
      "type": "boolean"
    },
    "has_children": {
      "type": "boolean",
      "readonly": true
    },
    "node_type": {
      "type": "string",
      "maxLength": 255
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "identifier": {
      "type": "string",
      "maxLength": 255
    },
    "children": {
      "type": "array",
      "additionalItems": false,
      "items": {
        "type": "JSONModel(:classification_tree) object"
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | minLength | maxLength | default | readonly | subtype | additionalItems | items  
 ----- | ---- | -------- | --------- | --------- | --------- | ------- | -------- | ------- | --------------- | ----- |  
 uri | string |  |  |  |  |  |  |  |  |  
 id | integer |  | error |  |  |  |  |  |  |  
 record_uri | string |  | error |  |  |  |  |  |  |  
 title | string |  |  | 1 | 16384 |  |  |  |  |  
 suppressed | boolean |  |  |  |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  |  
 has_children | boolean |  |  |  |  |  | true |  |  |  
 node_type | string |  |  |  | 255 |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  |  |  | true |  |  |  
 create_time | date-time |  |  |  |  |  | true |  |  |  
 repository | object |  |  |  |  |  | true | ref |  |  
 identifier | string |  |  |  | 255 |  |  |  |  |  
 children | array |  |  |  |  |  |  |  |  | {"type"=>"JSONModel(:classification_tree) object"} 




##JSONModel(:collection_management)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/collection_management",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "processing_hours_per_foot_estimate": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "processing_total_extent": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "processing_total_extent_type": {
      "type": "string",
      "required": false,
      "dynamic_enum": "extent_extent_type"
    },
    "processing_hours_total": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "processing_plan": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "processing_priority": {
      "type": "string",
      "required": false,
      "dynamic_enum": "collection_management_processing_priority"
    },
    "processing_funding_source": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "processors": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "rights_determined": {
      "type": "boolean",
      "default": false
    },
    "processing_status": {
      "type": "string",
      "required": false,
      "dynamic_enum": "collection_management_processing_status"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_collection_management"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | items | maxLength | dynamic_enum | default | ifmissing | readonly | subtype  
 ----- | ---- | -------- | ----- | --------- | ------------ | ------- | --------- | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 external_ids | array |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  |  
 processing_hours_per_foot_estimate | string |  |  | 255 |  |  |  |  |  
 processing_total_extent | string |  |  | 255 |  |  |  |  |  
 processing_total_extent_type | string |  |  |  | extent_extent_type |  |  |  |  
 processing_hours_total | string |  |  | 255 |  |  |  |  |  
 processing_plan | string |  |  | 65000 |  |  |  |  |  
 processing_priority | string |  |  |  | collection_management_processing_priority |  |  |  |  
 processing_funding_source | string |  |  | 65000 |  |  |  |  |  
 processors | string |  |  | 65000 |  |  |  |  |  
 rights_determined | boolean |  |  |  |  |  |  |  |  
 processing_status | string |  |  |  | collection_management_processing_status |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 




##JSONModel(:container)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "container_profile_key": {
      "type": "string"
    },
    "type_1": {
      "type": "string",
      "dynamic_enum": "container_type",
      "required": false
    },
    "indicator_1": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "required": false
    },
    "barcode_1": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1
    },
    "type_2": {
      "type": "string",
      "dynamic_enum": "container_type"
    },
    "indicator_2": {
      "type": "string",
      "maxLength": 255
    },
    "type_3": {
      "type": "string",
      "dynamic_enum": "container_type"
    },
    "indicator_3": {
      "type": "string",
      "maxLength": 255
    },
    "container_extent": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "container_extent_type": {
      "type": "string",
      "required": false,
      "dynamic_enum": "extent_extent_type"
    },
    "container_locations": {
      "type": "array",
      "items": {
        "type": "JSONModel(:container_location) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_container"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | dynamic_enum | required | maxLength | minLength | items | ifmissing | readonly | subtype  
 ----- | ---- | ------------ | -------- | --------- | --------- | ----- | --------- | -------- | ------- |  
 container_profile_key | string |  |  |  |  |  |  |  |  
 type_1 | string | container_type |  |  |  |  |  |  |  
 indicator_1 | string |  |  | 255 | 1 |  |  |  |  
 barcode_1 | string |  |  | 255 | 1 |  |  |  |  
 type_2 | string | container_type |  |  |  |  |  |  |  
 indicator_2 | string |  |  | 255 |  |  |  |  |  
 type_3 | string | container_type |  |  |  |  |  |  |  
 indicator_3 | string |  |  | 255 |  |  |  |  |  
 container_extent | string |  |  | 255 |  |  |  |  |  
 container_extent_type | string | extent_extent_type |  |  |  |  |  |  |  
 container_locations | array |  |  |  |  | {"type"=>"JSONModel(:container_location) object"} |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 




##JSONModel(:container_conversion_job)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "format": {
      "type": "string",
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | ifmissing | required | readonly | subtype  
 ----- | ---- | --------- | -------- | -------- | ------- |  
 format | string | error |  |  |  
 lock_version | integer | string |  |  |  |  
 jsonmodel_type | string | error |  |  |  
 created_by | string |  |  | true |  
 last_modified_by | string |  |  | true |  
 user_mtime | date-time |  |  | true |  
 system_mtime | date-time |  |  | true |  
 create_time | date-time |  |  | true |  
 repository | object |  |  | true | ref 




##JSONModel(:container_location)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "subtype": "ref",
  "properties": {
    "status": {
      "type": "string",
      "minLength": 1,
      "ifmissing": "error",
      "dynamic_enum": "container_location_status"
    },
    "start_date": {
      "type": "date",
      "minLength": 1,
      "ifmissing": "error"
    },
    "end_date": {
      "type": "date"
    },
    "note": {
      "type": "string"
    },
    "ref": {
      "type": "JSONModel(:location) uri",
      "ifmissing": "error"
    },
    "_resolved": {
      "type": "object",
      "readonly": "true"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_container_location"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | minLength | ifmissing | dynamic_enum | readonly | required | subtype  
 ----- | ---- | --------- | --------- | ------------ | -------- | -------- | ------- |  
 status | string | 1 | error | container_location_status |  |  |  
 start_date | date | 1 | error |  |  |  |  
 end_date | date |  |  |  |  |  |  
 note | string |  |  |  |  |  |  
 ref | JSONModel(:location) uri |  | error |  |  |  |  
 _resolved | object |  |  |  | true |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  
 created_by | string |  |  |  | true |  |  
 last_modified_by | string |  |  |  | true |  |  
 user_mtime | date-time |  |  |  | true |  |  
 system_mtime | date-time |  |  |  | true |  |  
 create_time | date-time |  |  |  | true |  |  
 repository | object |  |  |  | true |  | ref 




##JSONModel(:container_profile)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/container_profiles",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "name": {
      "type": "string",
      "ifmissing": "error"
    },
    "url": {
      "type": "string",
      "required": false
    },
    "dimension_units": {
      "type": "string",
      "ifmissing": "error",
      "dynamic_enum": "dimension_units"
    },
    "extent_dimension": {
      "type": "string",
      "ifmissing": "error",
      "enum": [
        "height",
        "width",
        "depth"
      ]
    },
    "height": {
      "type": "string",
      "ifmissing": "error"
    },
    "width": {
      "type": "string",
      "ifmissing": "error"
    },
    "depth": {
      "type": "string",
      "ifmissing": "error"
    },
    "stacking_limit": {
      "type": "string",
      "required": false
    },
    "display_string": {
      "type": "string",
      "readonly": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_container_profile"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | dynamic_enum | enum | readonly | subtype  
 ----- | ---- | -------- | --------- | ------------ | ---- | -------- | ------- |  
 uri | string |  |  |  |  |  |  
 name | string |  | error |  |  |  |  
 url | string |  |  |  |  |  |  
 dimension_units | string |  | error | dimension_units |  |  |  
 extent_dimension | string |  | error |  | height | width | depth |  |  
 height | string |  | error |  |  |  |  
 width | string |  | error |  |  |  |  
 depth | string |  | error |  |  |  |  
 stacking_limit | string |  |  |  |  |  |  
 display_string | string |  |  |  |  | true |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  
 created_by | string |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  | true |  
 create_time | date-time |  |  |  |  | true |  
 repository | object |  |  |  |  | true | ref 




##JSONModel(:date)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "date_type": {
      "type": "string",
      "dynamic_enum": "date_type",
      "ifmissing": "error"
    },
    "label": {
      "type": "string",
      "dynamic_enum": "date_label",
      "ifmissing": "error"
    },
    "certainty": {
      "type": "string",
      "dynamic_enum": "date_certainty"
    },
    "expression": {
      "type": "string",
      "maxLength": 255
    },
    "begin": {
      "type": "string",
      "maxLength": 255
    },
    "end": {
      "type": "string",
      "maxLength": 255
    },
    "era": {
      "type": "string",
      "dynamic_enum": "date_era"
    },
    "calendar": {
      "type": "string",
      "dynamic_enum": "date_calendar"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_date"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | dynamic_enum | ifmissing | maxLength | required | readonly | subtype  
 ----- | ---- | ------------ | --------- | --------- | -------- | -------- | ------- |  
 date_type | string | date_type | error |  |  |  |  
 label | string | date_label | error |  |  |  |  
 certainty | string | date_certainty |  |  |  |  |  
 expression | string |  |  | 255 |  |  |  
 begin | string |  |  | 255 |  |  |  
 end | string |  |  | 255 |  |  |  
 era | string | date_era |  |  |  |  |  
 calendar | string | date_calendar |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  
 created_by | string |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  | true |  
 create_time | date-time |  |  |  |  | true |  
 repository | object |  |  |  |  | true | ref 




##JSONModel(:date_field_query)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "comparator": {
      "type": "string",
      "enum": [
        "greater_than",
        "lesser_than",
        "equal"
      ]
    },
    "field": {
      "type": "string",
      "ifmissing": "error"
    },
    "value": {
      "type": "date",
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | enum | ifmissing | required | readonly | subtype  
 ----- | ---- | ---- | --------- | -------- | -------- | ------- |  
 comparator | string | greater_than | lesser_than | equal |  |  |  |  
 field | string |  | error |  |  |  
 value | date |  | error |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:deaccession)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "scope": {
      "type": "string",
      "dynamic_enum": "deaccession_scope",
      "ifmissing": "error"
    },
    "description": {
      "type": "string",
      "maxLength": 65000,
      "minLength": 1,
      "ifmissing": "error"
    },
    "reason": {
      "type": "string",
      "maxLength": 65000
    },
    "disposition": {
      "type": "string",
      "maxLength": 65000
    },
    "notification": {
      "type": "boolean",
      "default": false
    },
    "date": {
      "type": "JSONModel(:date) object",
      "ifmissing": "error"
    },
    "extents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:extent) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | dynamic_enum | ifmissing | maxLength | minLength | default | items | required | readonly | subtype  
 ----- | ---- | ------------ | --------- | --------- | --------- | ------- | ----- | -------- | -------- | ------- |  
 scope | string | deaccession_scope | error |  |  |  |  |  |  |  
 description | string |  | error | 65000 | 1 |  |  |  |  |  
 reason | string |  |  | 65000 |  |  |  |  |  |  
 disposition | string |  |  | 65000 |  |  |  |  |  |  
 notification | boolean |  |  |  |  |  |  |  |  |  
 date | JSONModel(:date) object |  | error |  |  |  |  |  |  |  
 extents | array |  |  |  |  |  | {"type"=>"JSONModel(:extent) object"} |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  |  |  
 created_by | string |  |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  |  | true | ref 




##JSONModel(:default_values)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/default_values/:record_type",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "record_type": {
      "type": "string",
      "ifmissing": "error",
      "enum": [
        "archival_object",
        "digital_object_component",
        "resource",
        "accession",
        "subject",
        "digital_object",
        "agent_person",
        "agent_family",
        "agent_software",
        "agent_corporate_entity",
        "event",
        "location",
        "classification",
        "classification_term"
      ]
    },
    "defaults": {
      "type": "object"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | enum | readonly | subtype  
 ----- | ---- | -------- | --------- | ---- | -------- | ------- |  
 uri | string |  |  |  |  |  
 record_type | string |  | error | archival_object | digital_object_component | resource | accession | subject | digital_object | agent_person | agent_family | agent_software | agent_corporate_entity | event | location | classification | classification_term |  |  
 defaults | object |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:defaults)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "show_suppressed": {
      "type": "boolean",
      "required": false
    },
    "publish": {
      "type": "boolean",
      "required": false
    },
    "accession_browse_column_1": {
      "type": "string",
      "enum": [
        "identifier",
        "accession_date",
        "acquisition_type",
        "resource_type",
        "restrictions_apply",
        "access_restrictions",
        "use_restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "accession_browse_column_2": {
      "type": "string",
      "enum": [
        "identifier",
        "accession_date",
        "acquisition_type",
        "resource_type",
        "restrictions_apply",
        "access_restrictions",
        "use_restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "accession_browse_column_3": {
      "type": "string",
      "enum": [
        "identifier",
        "accession_date",
        "acquisition_type",
        "resource_type",
        "restrictions_apply",
        "access_restrictions",
        "use_restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "accession_browse_column_4": {
      "type": "string",
      "enum": [
        "identifier",
        "accession_date",
        "acquisition_type",
        "resource_type",
        "restrictions_apply",
        "access_restrictions",
        "use_restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "accession_browse_column_5": {
      "type": "string",
      "enum": [
        "identifier",
        "accession_date",
        "acquisition_type",
        "resource_type",
        "restrictions_apply",
        "access_restrictions",
        "use_restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "resource_browse_column_1": {
      "type": "string",
      "enum": [
        "identifier",
        "resource_type",
        "level",
        "language",
        "restrictions",
        "ead_id",
        "finding_aid_status",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "resource_browse_column_2": {
      "type": "string",
      "enum": [
        "identifier",
        "resource_type",
        "level",
        "language",
        "restrictions",
        "ead_id",
        "finding_aid_status",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "resource_browse_column_3": {
      "type": "string",
      "enum": [
        "identifier",
        "resource_type",
        "level",
        "language",
        "restrictions",
        "ead_id",
        "finding_aid_status",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "resource_browse_column_4": {
      "type": "string",
      "enum": [
        "identifier",
        "resource_type",
        "level",
        "language",
        "restrictions",
        "ead_id",
        "finding_aid_status",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "resource_browse_column_5": {
      "type": "string",
      "enum": [
        "identifier",
        "resource_type",
        "level",
        "language",
        "restrictions",
        "ead_id",
        "finding_aid_status",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "digital_object_browse_column_1": {
      "type": "string",
      "enum": [
        "digital_object_id",
        "digital_object_type",
        "level",
        "restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "digital_object_browse_column_2": {
      "type": "string",
      "enum": [
        "digital_object_id",
        "digital_object_type",
        "level",
        "restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "digital_object_browse_column_3": {
      "type": "string",
      "enum": [
        "digital_object_id",
        "digital_object_type",
        "level",
        "restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "digital_object_browse_column_4": {
      "type": "string",
      "enum": [
        "digital_object_id",
        "digital_object_type",
        "level",
        "restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "digital_object_browse_column_5": {
      "type": "string",
      "enum": [
        "digital_object_id",
        "digital_object_type",
        "level",
        "restrictions",
        "publish",
        "no_value"
      ],
      "required": false
    },
    "default_values": {
      "type": "boolean",
      "required": false,
      "default": false
    },
    "note_order": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | enum | default | items | ifmissing | readonly | subtype  
 ----- | ---- | -------- | ---- | ------- | ----- | --------- | -------- | ------- |  
 show_suppressed | boolean |  |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 accession_browse_column_1 | string |  | identifier | accession_date | acquisition_type | resource_type | restrictions_apply | access_restrictions | use_restrictions | publish | no_value |  |  |  |  |  
 accession_browse_column_2 | string |  | identifier | accession_date | acquisition_type | resource_type | restrictions_apply | access_restrictions | use_restrictions | publish | no_value |  |  |  |  |  
 accession_browse_column_3 | string |  | identifier | accession_date | acquisition_type | resource_type | restrictions_apply | access_restrictions | use_restrictions | publish | no_value |  |  |  |  |  
 accession_browse_column_4 | string |  | identifier | accession_date | acquisition_type | resource_type | restrictions_apply | access_restrictions | use_restrictions | publish | no_value |  |  |  |  |  
 accession_browse_column_5 | string |  | identifier | accession_date | acquisition_type | resource_type | restrictions_apply | access_restrictions | use_restrictions | publish | no_value |  |  |  |  |  
 resource_browse_column_1 | string |  | identifier | resource_type | level | language | restrictions | ead_id | finding_aid_status | publish | no_value |  |  |  |  |  
 resource_browse_column_2 | string |  | identifier | resource_type | level | language | restrictions | ead_id | finding_aid_status | publish | no_value |  |  |  |  |  
 resource_browse_column_3 | string |  | identifier | resource_type | level | language | restrictions | ead_id | finding_aid_status | publish | no_value |  |  |  |  |  
 resource_browse_column_4 | string |  | identifier | resource_type | level | language | restrictions | ead_id | finding_aid_status | publish | no_value |  |  |  |  |  
 resource_browse_column_5 | string |  | identifier | resource_type | level | language | restrictions | ead_id | finding_aid_status | publish | no_value |  |  |  |  |  
 digital_object_browse_column_1 | string |  | digital_object_id | digital_object_type | level | restrictions | publish | no_value |  |  |  |  |  
 digital_object_browse_column_2 | string |  | digital_object_id | digital_object_type | level | restrictions | publish | no_value |  |  |  |  |  
 digital_object_browse_column_3 | string |  | digital_object_id | digital_object_type | level | restrictions | publish | no_value |  |  |  |  |  
 digital_object_browse_column_4 | string |  | digital_object_id | digital_object_type | level | restrictions | publish | no_value |  |  |  |  |  
 digital_object_browse_column_5 | string |  | digital_object_id | digital_object_type | level | restrictions | publish | no_value |  |  |  |  |  
 default_values | boolean |  |  |  |  |  |  |  
 note_order | array |  |  |  | {"type"=>"string"} |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  | true | ref 




##JSONModel(:digital_object)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_archival_object",
  "uri": "/repositories/:repo_id/digital_objects",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 16384,
      "ifmissing": "error"
    },
    "language": {
      "type": "string",
      "dynamic_enum": "language_iso639_2"
    },
    "publish": {
      "type": "boolean"
    },
    "subjects": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:subject) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "linked_events": {
      "type": "array",
      "readonly": "true",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:event) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "extents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:extent) object"
      }
    },
    "dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "linked_agents": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "role": {
            "type": "string",
            "dynamic_enum": "linked_agent_role",
            "ifmissing": "error"
          },
          "terms": {
            "type": "array",
            "items": {
              "type": "JSONModel(:term) uri_or_object"
            }
          },
          "relator": {
            "type": "string",
            "dynamic_enum": "linked_agent_archival_record_relators"
          },
          "title": {
            "type": "string"
          },
          "ref": {
            "type": [
              {
                "type": "JSONModel(:agent_corporate_entity) uri"
              },
              {
                "type": "JSONModel(:agent_family) uri"
              },
              {
                "type": "JSONModel(:agent_person) uri"
              },
              {
                "type": "JSONModel(:agent_software) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "suppressed": {
      "type": "boolean",
      "readonly": "true"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "digital_object_id": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error"
    },
    "level": {
      "type": "string",
      "dynamic_enum": "digital_object_level"
    },
    "digital_object_type": {
      "type": "string",
      "dynamic_enum": "digital_object_digital_object_type"
    },
    "file_versions": {
      "type": "array",
      "items": {
        "type": "JSONModel(:file_version) object"
      }
    },
    "restrictions": {
      "type": "boolean",
      "default": false
    },
    "tree": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:digital_object_tree) uri",
          "ifmissing": "error"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "notes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_bibliography) object"
          },
          {
            "type": "JSONModel(:note_digital_object) object"
          }
        ]
      }
    },
    "collection_management": {
      "type": "JSONModel(:collection_management) object"
    },
    "user_defined": {
      "type": "JSONModel(:user_defined) object"
    },
    "linked_instances": {
      "type": "array",
      "readonly": "true",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              "JSONModel(:resource) uri",
              "JSONModel(:archival_object) object"
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | items | minLength | maxLength | ifmissing | dynamic_enum | readonly | subtype | default  
 ----- | ---- | -------- | ----- | --------- | --------- | --------- | ------------ | -------- | ------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  |  
 external_ids | array |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  |  |  
 title | string |  |  | 1 | 16384 | error |  |  |  |  
 language | string |  |  |  |  |  | language_iso639_2 |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  |  
 subjects | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:subject) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  
 linked_events | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:event) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  | true |  |  
 extents | array |  | {"type"=>"JSONModel(:extent) object"} |  |  |  |  |  |  |  
 dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  |  
 external_documents | array |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  |  |  |  |  
 rights_statements | array |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  |  |  |  |  
 linked_agents | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"role"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_role", "ifmissing"=>"error"}, "terms"=>{"type"=>"array", "items"=>{"type"=>"JSONModel(:term) uri_or_object"}}, "relator"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_archival_record_relators"}, "title"=>{"type"=>"string"}, "ref"=>{"type"=>[{"type"=>"JSONModel(:agent_corporate_entity) uri"}, {"type"=>"JSONModel(:agent_family) uri"}, {"type"=>"JSONModel(:agent_person) uri"}, {"type"=>"JSONModel(:agent_software) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  
 suppressed | boolean |  |  |  |  |  |  | true |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  |  |  
 created_by | string |  |  |  |  |  |  | true |  |  
 last_modified_by | string |  |  |  |  |  |  | true |  |  
 user_mtime | date-time |  |  |  |  |  |  | true |  |  
 system_mtime | date-time |  |  |  |  |  |  | true |  |  
 create_time | date-time |  |  |  |  |  |  | true |  |  
 repository | object |  |  |  |  |  |  | true | ref |  
 digital_object_id | string |  |  |  | 255 | error |  |  |  |  
 level | string |  |  |  |  |  | digital_object_level |  |  |  
 digital_object_type | string |  |  |  |  |  | digital_object_digital_object_type |  |  |  
 file_versions | array |  | {"type"=>"JSONModel(:file_version) object"} |  |  |  |  |  |  |  
 restrictions | boolean |  |  |  |  |  |  |  |  |  
 tree | object |  |  |  |  |  |  |  | ref |  
 notes | array |  | {"type"=>[{"type"=>"JSONModel(:note_bibliography) object"}, {"type"=>"JSONModel(:note_digital_object) object"}]} |  |  |  |  |  |  |  
 collection_management | JSONModel(:collection_management) object |  |  |  |  |  |  |  |  |  
 user_defined | JSONModel(:user_defined) object |  |  |  |  |  |  |  |  |  
 linked_instances | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>["JSONModel(:resource) uri", "JSONModel(:archival_object) object"], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  | true |  |  




##JSONModel(:digital_object_component)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_archival_object",
  "uri": "/repositories/:repo_id/digital_object_components",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 16384,
      "ifmissing": null
    },
    "language": {
      "type": "string",
      "dynamic_enum": "language_iso639_2"
    },
    "publish": {
      "type": "boolean"
    },
    "subjects": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:subject) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "linked_events": {
      "type": "array",
      "readonly": "true",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:event) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "extents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:extent) object"
      }
    },
    "dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "linked_agents": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "role": {
            "type": "string",
            "dynamic_enum": "linked_agent_role",
            "ifmissing": "error"
          },
          "terms": {
            "type": "array",
            "items": {
              "type": "JSONModel(:term) uri_or_object"
            }
          },
          "relator": {
            "type": "string",
            "dynamic_enum": "linked_agent_archival_record_relators"
          },
          "title": {
            "type": "string"
          },
          "ref": {
            "type": [
              {
                "type": "JSONModel(:agent_corporate_entity) uri"
              },
              {
                "type": "JSONModel(:agent_family) uri"
              },
              {
                "type": "JSONModel(:agent_person) uri"
              },
              {
                "type": "JSONModel(:agent_software) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "suppressed": {
      "type": "boolean",
      "readonly": "true"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "component_id": {
      "type": "string",
      "maxLength": 255
    },
    "label": {
      "type": "string",
      "maxLength": 255
    },
    "display_string": {
      "type": "string",
      "maxLength": 8192,
      "readonly": true
    },
    "file_versions": {
      "type": "array",
      "items": {
        "type": "JSONModel(:file_version) object"
      }
    },
    "parent": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:digital_object_component) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "digital_object": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:digital_object) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "position": {
      "type": "integer",
      "required": false
    },
    "notes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_bibliography) object"
          },
          {
            "type": "JSONModel(:note_digital_object) object"
          }
        ]
      }
    },
    "has_unpublished_ancestor": {
      "type": "boolean",
      "readonly": "true"
    }
  },
  "validations": [
    [
      "error",
      "check_digital_object_component"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | items | minLength | maxLength | ifmissing | dynamic_enum | readonly | subtype  
 ----- | ---- | -------- | ----- | --------- | --------- | --------- | ------------ | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 external_ids | array |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  |  
 title | string |  |  | 1 | 16384 |  |  |  |  
 language | string |  |  |  |  |  | language_iso639_2 |  |  
 publish | boolean |  |  |  |  |  |  |  |  
 subjects | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:subject) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  
 linked_events | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:event) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  | true |  
 extents | array |  | {"type"=>"JSONModel(:extent) object"} |  |  |  |  |  |  
 dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  
 external_documents | array |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  |  |  |  
 rights_statements | array |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  |  |  |  
 linked_agents | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"role"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_role", "ifmissing"=>"error"}, "terms"=>{"type"=>"array", "items"=>{"type"=>"JSONModel(:term) uri_or_object"}}, "relator"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_archival_record_relators"}, "title"=>{"type"=>"string"}, "ref"=>{"type"=>[{"type"=>"JSONModel(:agent_corporate_entity) uri"}, {"type"=>"JSONModel(:agent_family) uri"}, {"type"=>"JSONModel(:agent_person) uri"}, {"type"=>"JSONModel(:agent_software) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  
 suppressed | boolean |  |  |  |  |  |  | true |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 
 component_id | string |  |  |  | 255 |  |  |  |  
 label | string |  |  |  | 255 |  |  |  |  
 display_string | string |  |  |  | 8192 |  |  | true |  
 file_versions | array |  | {"type"=>"JSONModel(:file_version) object"} |  |  |  |  |  |  
 parent | object |  |  |  |  |  |  |  | ref 
 digital_object | object |  |  |  |  |  |  |  | ref 
 position | integer |  |  |  |  |  |  |  |  
 notes | array |  | {"type"=>[{"type"=>"JSONModel(:note_bibliography) object"}, {"type"=>"JSONModel(:note_digital_object) object"}]} |  |  |  |  |  |  
 has_unpublished_ancestor | boolean |  |  |  |  |  |  | true |  




##JSONModel(:digital_object_tree)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/digital_objects/:digital_object_id/tree",
  "parent": "record_tree",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "id": {
      "type": "integer",
      "ifmissing": "error"
    },
    "record_uri": {
      "type": "string",
      "ifmissing": "error"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "required": false,
      "maxLength": 16384
    },
    "suppressed": {
      "type": "boolean",
      "default": false
    },
    "publish": {
      "type": "boolean"
    },
    "has_children": {
      "type": "boolean",
      "readonly": true
    },
    "node_type": {
      "type": "string",
      "maxLength": 255
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "level": {
      "type": "string",
      "maxLength": 255
    },
    "digital_object_type": {
      "type": "string",
      "maxLength": 255
    },
    "file_versions": {
      "type": "array",
      "items": {
        "type": "object"
      }
    },
    "children": {
      "type": "array",
      "additionalItems": false,
      "items": {
        "type": "JSONModel(:digital_object_tree) object"
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | minLength | maxLength | default | readonly | subtype | items | additionalItems  
 ----- | ---- | -------- | --------- | --------- | --------- | ------- | -------- | ------- | ----- | --------------- |  
 uri | string |  |  |  |  |  |  |  |  |  
 id | integer |  | error |  |  |  |  |  |  |  
 record_uri | string |  | error |  |  |  |  |  |  |  
 title | string |  |  | 1 | 16384 |  |  |  |  |  
 suppressed | boolean |  |  |  |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  |  
 has_children | boolean |  |  |  |  |  | true |  |  |  
 node_type | string |  |  |  | 255 |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  |  |  | true |  |  |  
 create_time | date-time |  |  |  |  |  | true |  |  |  
 repository | object |  |  |  |  |  | true | ref |  |  
 level | string |  |  |  | 255 |  |  |  |  |  
 digital_object_type | string |  |  |  | 255 |  |  |  |  |  
 file_versions | array |  |  |  |  |  |  |  | {"type"=>"object"} |  
 children | array |  |  |  |  |  |  |  | {"type"=>"JSONModel(:digital_object_tree) object"} |  




##JSONModel(:digital_record_children)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "children": {
      "type": "array",
      "items": {
        "type": "JSONModel(:digital_object_component) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | items | required | ifmissing | readonly | subtype  
 ----- | ---- | ----- | -------- | --------- | -------- | ------- |  
 children | array | {"type"=>"JSONModel(:digital_object_component) object"} |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:enumeration)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/config/enumerations",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "name": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error"
    },
    "default_value": {
      "type": "string"
    },
    "editable": {
      "type": "boolean",
      "readonly": true
    },
    "relationships": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "enumeration_values": {
      "type": "array",
      "items": {
        "type": "JSONModel(:enumeration_value) object"
      }
    },
    "values": {
      "type": "array",
      "ifmissing": "error",
      "items": {
        "type": "string"
      }
    },
    "readonly_values": {
      "type": "array",
      "readonly": true,
      "items": {
        "type": "string"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | readonly | items | subtype  
 ----- | ---- | -------- | --------- | --------- | -------- | ----- | ------- |  
 uri | string |  |  |  |  |  |  
 name | string |  | 255 | error |  |  |  
 default_value | string |  |  |  |  |  |  
 editable | boolean |  |  |  | true |  |  
 relationships | array |  |  |  |  | {"type"=>"string"} |  
 enumeration_values | array |  |  |  |  | {"type"=>"JSONModel(:enumeration_value) object"} |  
 values | array |  |  | error |  | {"type"=>"string"} |  
 readonly_values | array |  |  |  | true | {"type"=>"string"} |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  
 created_by | string |  |  |  | true |  |  
 last_modified_by | string |  |  |  | true |  |  
 user_mtime | date-time |  |  |  | true |  |  
 system_mtime | date-time |  |  |  | true |  |  
 create_time | date-time |  |  |  | true |  |  
 repository | object |  |  |  | true |  | ref 




##JSONModel(:enumeration_migration)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/config/enumerations/migration",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "enum_uri": {
      "type": "JSONModel(:enumeration) uri",
      "ifmissing": "error"
    },
    "from": {
      "type": "string",
      "ifmissing": "error"
    },
    "to": {
      "type": "string",
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | readonly | subtype  
 ----- | ---- | -------- | --------- | -------- | ------- |  
 uri | string |  |  |  |  
 enum_uri | JSONModel(:enumeration) uri |  | error |  |  
 from | string |  | error |  |  
 to | string |  | error |  |  
 lock_version | integer | string |  |  |  |  
 jsonmodel_type | string |  | error |  |  
 created_by | string |  |  | true |  
 last_modified_by | string |  |  | true |  
 user_mtime | date-time |  |  | true |  
 system_mtime | date-time |  |  | true |  
 create_time | date-time |  |  | true |  
 repository | object |  |  | true | ref 




##JSONModel(:enumeration_value)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/config/enumeration_values",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "value": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error"
    },
    "position": {
      "type": "integer"
    },
    "suppressed": {
      "type": "boolean"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | readonly | subtype  
 ----- | ---- | -------- | --------- | --------- | -------- | ------- |  
 uri | string |  |  |  |  |  
 value | string |  | 255 | error |  |  
 position | integer |  |  |  |  |  
 suppressed | boolean |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:event)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/events",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "event_type": {
      "type": "string",
      "ifmissing": "error",
      "dynamic_enum": "event_event_type"
    },
    "date": {
      "type": "JSONModel(:date) object"
    },
    "timestamp": {
      "type": "string"
    },
    "outcome": {
      "type": "string",
      "dynamic_enum": "event_outcome"
    },
    "outcome_note": {
      "type": "string",
      "maxLength": 16384
    },
    "suppressed": {
      "type": "boolean",
      "readonly": "true"
    },
    "linked_agents": {
      "type": "array",
      "ifmissing": "error",
      "minItems": 1,
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "role": {
            "type": "string",
            "dynamic_enum": "linked_agent_event_roles",
            "ifmissing": "error"
          },
          "ref": {
            "type": [
              {
                "type": "JSONModel(:agent_corporate_entity) uri"
              },
              {
                "type": "JSONModel(:agent_family) uri"
              },
              {
                "type": "JSONModel(:agent_person) uri"
              },
              {
                "type": "JSONModel(:agent_software) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "linked_records": {
      "type": "array",
      "ifmissing": "error",
      "minItems": 1,
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "role": {
            "type": "string",
            "dynamic_enum": "linked_event_archival_record_roles",
            "ifmissing": "error"
          },
          "ref": {
            "type": [
              {
                "type": "JSONModel(:agent_person) uri"
              },
              {
                "type": "JSONModel(:agent_family) uri"
              },
              {
                "type": "JSONModel(:agent_corporate_entity) uri"
              },
              {
                "type": "JSONModel(:agent_software) uri"
              },
              {
                "type": "JSONModel(:accession) uri"
              },
              {
                "type": "JSONModel(:resource) uri"
              },
              {
                "type": "JSONModel(:digital_object) uri"
              },
              {
                "type": "JSONModel(:archival_object) uri"
              },
              {
                "type": "JSONModel(:digital_object_component) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_event"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | items | ifmissing | dynamic_enum | maxLength | readonly | minItems | subtype  
 ----- | ---- | -------- | ----- | --------- | ------------ | --------- | -------- | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 external_ids | array |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  |  
 external_documents | array |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  |  |  |  
 event_type | string |  |  | error | event_event_type |  |  |  |  
 date | JSONModel(:date) object |  |  |  |  |  |  |  |  
 timestamp | string |  |  |  |  |  |  |  |  
 outcome | string |  |  |  | event_outcome |  |  |  |  
 outcome_note | string |  |  |  |  | 16384 |  |  |  
 suppressed | boolean |  |  |  |  |  | true |  |  
 linked_agents | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"role"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_event_roles", "ifmissing"=>"error"}, "ref"=>{"type"=>[{"type"=>"JSONModel(:agent_corporate_entity) uri"}, {"type"=>"JSONModel(:agent_family) uri"}, {"type"=>"JSONModel(:agent_person) uri"}, {"type"=>"JSONModel(:agent_software) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} | error |  |  |  | 1 |  
 linked_records | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"role"=>{"type"=>"string", "dynamic_enum"=>"linked_event_archival_record_roles", "ifmissing"=>"error"}, "ref"=>{"type"=>[{"type"=>"JSONModel(:agent_person) uri"}, {"type"=>"JSONModel(:agent_family) uri"}, {"type"=>"JSONModel(:agent_corporate_entity) uri"}, {"type"=>"JSONModel(:agent_software) uri"}, {"type"=>"JSONModel(:accession) uri"}, {"type"=>"JSONModel(:resource) uri"}, {"type"=>"JSONModel(:digital_object) uri"}, {"type"=>"JSONModel(:archival_object) uri"}, {"type"=>"JSONModel(:digital_object_component) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} | error |  |  |  | 1 |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  |  
 last_modified_by | string |  |  |  |  |  | true |  |  
 user_mtime | date-time |  |  |  |  |  | true |  |  
 system_mtime | date-time |  |  |  |  |  | true |  |  
 create_time | date-time |  |  |  |  |  | true |  |  
 repository | object |  |  |  |  |  | true |  | ref 




##JSONModel(:extent)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "portion": {
      "type": "string",
      "minLength": 1,
      "ifmissing": "error",
      "dynamic_enum": "extent_portion"
    },
    "number": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "ifmissing": "error"
    },
    "extent_type": {
      "type": "string",
      "minLength": 1,
      "ifmissing": "error",
      "dynamic_enum": "extent_extent_type"
    },
    "container_summary": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "physical_details": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "dimensions": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | minLength | ifmissing | dynamic_enum | maxLength | required | readonly | subtype  
 ----- | ---- | --------- | --------- | ------------ | --------- | -------- | -------- | ------- |  
 portion | string | 1 | error | extent_portion |  |  |  |  
 number | string | 1 | error |  | 255 |  |  |  
 extent_type | string | 1 | error | extent_extent_type |  |  |  |  
 container_summary | string |  |  |  | 65000 |  |  |  
 physical_details | string |  |  |  | 65000 |  |  |  
 dimensions | string |  |  |  | 255 |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  | true | ref 




##JSONModel(:external_document)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "title": {
      "type": "string",
      "maxLength": 16384,
      "ifmissing": "error",
      "minLength": 1
    },
    "location": {
      "type": "string",
      "maxLength": 16384,
      "ifmissing": "error",
      "default": ""
    },
    "publish": {
      "type": "boolean"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | ifmissing | minLength | default | required | readonly | subtype  
 ----- | ---- | --------- | --------- | --------- | ------- | -------- | -------- | ------- |  
 title | string | 16384 | error | 1 |  |  |  |  
 location | string | 16384 | error |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  | true | ref 




##JSONModel(:external_id)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "external_id": {
      "type": "string",
      "maxLength": 255
    },
    "source": {
      "type": "string",
      "maxLength": 255
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- |  
 external_id | string | 255 |  |  |  |  
 source | string | 255 |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:field_query)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "negated": {
      "type": "boolean",
      "default": false
    },
    "field": {
      "type": "string",
      "ifmissing": "error"
    },
    "value": {
      "type": "string",
      "ifmissing": "error"
    },
    "literal": {
      "type": "boolean",
      "default": false
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | default | ifmissing | required | readonly | subtype  
 ----- | ---- | ------- | --------- | -------- | -------- | ------- |  
 negated | boolean |  |  |  |  |  
 field | string |  | error |  |  |  
 value | string |  | error |  |  |  
 literal | boolean |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:file_version)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "identifier": {
      "type": "string",
      "readonly": true
    },
    "file_uri": {
      "type": "string",
      "maxLength": 16384,
      "ifmissing": "error"
    },
    "publish": {
      "type": "boolean"
    },
    "use_statement": {
      "type": "string",
      "dynamic_enum": "file_version_use_statement"
    },
    "xlink_actuate_attribute": {
      "type": "string",
      "dynamic_enum": "file_version_xlink_actuate_attribute"
    },
    "xlink_show_attribute": {
      "type": "string",
      "dynamic_enum": "file_version_xlink_show_attribute"
    },
    "file_format_name": {
      "type": "string",
      "dynamic_enum": "file_version_file_format_name"
    },
    "file_format_version": {
      "type": "string",
      "maxLength": 255
    },
    "file_size_bytes": {
      "type": "integer"
    },
    "is_representative": {
      "type": "boolean",
      "default": false
    },
    "checksum": {
      "type": "string",
      "maxLength": 255
    },
    "checksum_method": {
      "type": "string",
      "dynamic_enum": "file_version_checksum_methods"
    },
    "caption": {
      "type": "string",
      "maxLength": 16384
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | readonly | maxLength | ifmissing | dynamic_enum | default | required | subtype  
 ----- | ---- | -------- | --------- | --------- | ------------ | ------- | -------- | ------- |  
 identifier | string | true |  |  |  |  |  |  
 file_uri | string |  | 16384 | error |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 use_statement | string |  |  |  | file_version_use_statement |  |  |  
 xlink_actuate_attribute | string |  |  |  | file_version_xlink_actuate_attribute |  |  |  
 xlink_show_attribute | string |  |  |  | file_version_xlink_show_attribute |  |  |  
 file_format_name | string |  |  |  | file_version_file_format_name |  |  |  
 file_format_version | string |  | 255 |  |  |  |  |  
 file_size_bytes | integer |  |  |  |  |  |  |  
 is_representative | boolean |  |  |  |  |  |  |  
 checksum | string |  | 255 |  |  |  |  |  
 checksum_method | string |  |  |  | file_version_checksum_methods |  |  |  
 caption | string |  | 16384 |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  
 created_by | string | true |  |  |  |  |  |  
 last_modified_by | string | true |  |  |  |  |  |  
 user_mtime | date-time | true |  |  |  |  |  |  
 system_mtime | date-time | true |  |  |  |  |  |  
 create_time | date-time | true |  |  |  |  |  |  
 repository | object | true |  |  |  |  |  | ref 




##JSONModel(:find_and_replace_job)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "find": {
      "type": "string",
      "ifmissing": "error"
    },
    "replace": {
      "type": "string",
      "ifmissing": "error"
    },
    "record_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "property": {
      "type": "string",
      "ifmissing": "error"
    },
    "base_record_uri": {
      "type": "string",
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "only target properties on the target schemas"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | ifmissing | required | readonly | subtype  
 ----- | ---- | --------- | -------- | -------- | ------- |  
 find | string | error |  |  |  
 replace | string | error |  |  |  
 record_type | string | error |  |  |  
 property | string | error |  |  |  
 base_record_uri | string | error |  |  |  
 lock_version | integer | string |  |  |  |  
 jsonmodel_type | string | error |  |  |  
 created_by | string |  |  | true |  
 last_modified_by | string |  |  | true |  
 user_mtime | date-time |  |  | true |  
 system_mtime | date-time |  |  | true |  
 create_time | date-time |  |  | true |  
 repository | object |  |  | true | ref 




##JSONModel(:group)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/groups",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "group_code": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error",
      "minLength": 1
    },
    "description": {
      "type": "string",
      "maxLength": 65000,
      "ifmissing": "error",
      "default": ""
    },
    "member_usernames": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "grants_permissions": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | minLength | default | items | readonly | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ------- | ----- | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 group_code | string |  | 255 | error | 1 |  |  |  |  
 description | string |  | 65000 | error |  |  |  |  |  
 member_usernames | array |  |  |  |  |  | {"type"=>"string", "minLength"=>1} |  |  
 grants_permissions | array |  |  |  |  |  | {"type"=>"string", "minLength"=>1} |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 




##JSONModel(:import_job)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "filenames": {
      "type": "array",
      "ifmissing": "error",
      "minItems": 1,
      "items": {
        "type": "string"
      }
    },
    "import_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | ifmissing | minItems | items | required | readonly | subtype  
 ----- | ---- | --------- | -------- | ----- | -------- | -------- | ------- |  
 filenames | array | error | 1 | {"type"=>"string"} |  |  |  
 import_type | string | error |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string | error |  |  |  |  |  
 created_by | string |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  | true |  
 create_time | date-time |  |  |  |  | true |  
 repository | object |  |  |  |  | true | ref 




##JSONModel(:instance)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "instance_type": {
      "type": "string",
      "minLength": 1,
      "ifmissing": "error",
      "dynamic_enum": "instance_instance_type"
    },
    "container": {
      "type": "JSONModel(:container) object"
    },
    "sub_container": {
      "type": "JSONModel(:sub_container) object"
    },
    "digital_object": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:digital_object) uri",
          "ifmissing": "error"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "is_representative": {
      "type": "boolean",
      "default": false
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_instance"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | minLength | ifmissing | dynamic_enum | subtype | default | required | readonly  
 ----- | ---- | --------- | --------- | ------------ | ------- | ------- | -------- | -------- |  
 instance_type | string | 1 | error | instance_instance_type |  |  |  |  
 container | JSONModel(:container) object |  |  |  |  |  |  |  
 sub_container | JSONModel(:sub_container) object |  |  |  |  |  |  |  
 digital_object | object |  |  |  | ref |  |  |  
 is_representative | boolean |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  |  | true 
 last_modified_by | string |  |  |  |  |  |  | true 
 user_mtime | date-time |  |  |  |  |  |  | true 
 system_mtime | date-time |  |  |  |  |  |  | true 
 create_time | date-time |  |  |  |  |  |  | true 
 repository | object |  |  |  | ref |  |  | true 




##JSONModel(:job)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/jobs",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "job_type": {
      "type": "string",
      "ifmissing": "error",
      "minLength": 1,
      "dynamic_enum": "job_type"
    },
    "job": {
      "type": [
        {
          "type": "JSONModel(:import_job) object"
        },
        {
          "type": "JSONModel(:find_and_replace_job) object"
        },
        {
          "type": "JSONModel(:print_to_pdf_job) object"
        },
        {
          "type": "JSONModel(:report_job) object"
        },
        {
          "type": "JSONModel(:container_conversion_job) object"
        }
      ]
    },
    "job_params": {
      "type": "string"
    },
    "time_submitted": {
      "type": "date-time",
      "readonly": true
    },
    "time_started": {
      "type": "date-time",
      "readonly": true
    },
    "time_finished": {
      "type": "date-time",
      "readonly": true
    },
    "owner": {
      "type": "string",
      "readonly": true
    },
    "status": {
      "type": "string",
      "enum": [
        "running",
        "completed",
        "canceled",
        "queued",
        "failed"
      ],
      "default": "queued",
      "readonly": true
    },
    "queue_position": {
      "type": "number",
      "readonly": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | minLength | dynamic_enum | readonly | enum | default | subtype  
 ----- | ---- | -------- | --------- | --------- | ------------ | -------- | ---- | ------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 job_type | string |  | error | 1 | job_type |  |  |  |  
 job | {"type"=>"JSONModel(:import_job) object"} | {"type"=>"JSONModel(:find_and_replace_job) object"} | {"type"=>"JSONModel(:print_to_pdf_job) object"} | {"type"=>"JSONModel(:report_job) object"} | {"type"=>"JSONModel(:container_conversion_job) object"} |  |  |  |  |  |  |  |  
 job_params | string |  |  |  |  |  |  |  |  
 time_submitted | date-time |  |  |  |  | true |  |  |  
 time_started | date-time |  |  |  |  | true |  |  |  
 time_finished | date-time |  |  |  |  | true |  |  |  
 owner | string |  |  |  |  | true |  |  |  
 status | string |  |  |  |  | true | running | completed | canceled | queued | failed | queued |  
 queue_position | number |  |  |  |  | true |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  |  
 created_by | string |  |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  |  | true |  |  |  
 create_time | date-time |  |  |  |  | true |  |  |  
 repository | object |  |  |  |  | true |  |  | ref 




##JSONModel(:location)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/locations",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "title": {
      "type": "string",
      "readonly": true
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "building": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "ifmissing": "error"
    },
    "floor": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "room": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "area": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "barcode": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "classification": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_1_label": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_1_indicator": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_2_label": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_2_indicator": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_3_label": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_3_indicator": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "temporary": {
      "type": "string",
      "dynamic_enum": "location_temporary"
    },
    "location_profile": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:location_profile) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "owner_repo": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "functions": {
      "type": "array",
      "items": {
        "type": "JSONModel(:location_function) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_location"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | readonly | items | maxLength | minLength | ifmissing | dynamic_enum | subtype  
 ----- | ---- | -------- | -------- | ----- | --------- | --------- | --------- | ------------ | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 title | string |  | true |  |  |  |  |  |  
 external_ids | array |  |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  
 building | string |  |  |  | 255 | 1 | error |  |  
 floor | string |  |  |  | 255 |  |  |  |  
 room | string |  |  |  | 255 |  |  |  |  
 area | string |  |  |  | 255 |  |  |  |  
 barcode | string |  |  |  | 255 |  |  |  |  
 classification | string |  |  |  | 255 |  |  |  |  
 coordinate_1_label | string |  |  |  | 255 |  |  |  |  
 coordinate_1_indicator | string |  |  |  | 255 |  |  |  |  
 coordinate_2_label | string |  |  |  | 255 |  |  |  |  
 coordinate_2_indicator | string |  |  |  | 255 |  |  |  |  
 coordinate_3_label | string |  |  |  | 255 |  |  |  |  
 coordinate_3_indicator | string |  |  |  | 255 |  |  |  |  
 temporary | string |  |  |  |  |  |  | location_temporary |  
 location_profile | object |  |  |  |  |  |  |  | ref 
 owner_repo | object |  |  |  |  |  |  |  | ref 
 functions | array |  |  | {"type"=>"JSONModel(:location_function) object"} |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  | true |  |  |  |  |  |  
 last_modified_by | string |  | true |  |  |  |  |  |  
 user_mtime | date-time |  | true |  |  |  |  |  |  
 system_mtime | date-time |  | true |  |  |  |  |  |  
 create_time | date-time |  | true |  |  |  |  |  |  
 repository | object |  | true |  |  |  |  |  | ref 




##JSONModel(:location_batch)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "location",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "title": {
      "type": "string",
      "readonly": true
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "building": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "ifmissing": "error"
    },
    "floor": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "room": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "area": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "barcode": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "classification": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_1_label": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_1_indicator": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_2_label": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_2_indicator": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_3_label": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_3_indicator": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "temporary": {
      "type": "string",
      "dynamic_enum": "location_temporary"
    },
    "location_profile": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:location_profile) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "owner_repo": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "functions": {
      "type": "array",
      "items": {
        "type": "JSONModel(:location_function) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "locations": {
      "type": "array",
      "items": {
        "type": "JSONModel(:location) uri"
      }
    },
    "coordinate_1_range": {
      "type": "object",
      "ifmissing": "error",
      "properties": {
        "label": {
          "type": "string",
          "ifmissing": "error"
        },
        "start": {
          "type": "string",
          "ifmissing": "error",
          "minLength": 1
        },
        "end": {
          "type": "string",
          "ifmissing": "error",
          "minLength": 1
        },
        "prefix": {
          "type": "string"
        },
        "suffix": {
          "type": "string"
        }
      }
    },
    "coordinate_2_range": {
      "type": "object",
      "properties": {
        "label": {
          "type": "string",
          "ifmissing": "error"
        },
        "start": {
          "type": "string",
          "ifmissing": "error",
          "minLength": 1
        },
        "end": {
          "type": "string",
          "ifmissing": "error",
          "minLength": 1
        },
        "prefix": {
          "type": "string"
        },
        "suffix": {
          "type": "string"
        }
      }
    },
    "coordinate_3_range": {
      "type": "object",
      "properties": {
        "label": {
          "type": "string",
          "ifmissing": "error"
        },
        "start": {
          "type": "string",
          "ifmissing": "error",
          "minLength": 1
        },
        "end": {
          "type": "string",
          "ifmissing": "error",
          "minLength": 1
        },
        "prefix": {
          "type": "string"
        },
        "suffix": {
          "type": "string"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | readonly | items | maxLength | minLength | ifmissing | dynamic_enum | subtype  
 ----- | ---- | -------- | -------- | ----- | --------- | --------- | --------- | ------------ | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 title | string |  | true |  |  |  |  |  |  
 external_ids | array |  |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  
 building | string |  |  |  | 255 | 1 | error |  |  
 floor | string |  |  |  | 255 |  |  |  |  
 room | string |  |  |  | 255 |  |  |  |  
 area | string |  |  |  | 255 |  |  |  |  
 barcode | string |  |  |  | 255 |  |  |  |  
 classification | string |  |  |  | 255 |  |  |  |  
 coordinate_1_label | string |  |  |  | 255 |  |  |  |  
 coordinate_1_indicator | string |  |  |  | 255 |  |  |  |  
 coordinate_2_label | string |  |  |  | 255 |  |  |  |  
 coordinate_2_indicator | string |  |  |  | 255 |  |  |  |  
 coordinate_3_label | string |  |  |  | 255 |  |  |  |  
 coordinate_3_indicator | string |  |  |  | 255 |  |  |  |  
 temporary | string |  |  |  |  |  |  | location_temporary |  
 location_profile | object |  |  |  |  |  |  |  | ref 
 owner_repo | object |  |  |  |  |  |  |  | ref 
 functions | array |  |  | {"type"=>"JSONModel(:location_function) object"} |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  | true |  |  |  |  |  |  
 last_modified_by | string |  | true |  |  |  |  |  |  
 user_mtime | date-time |  | true |  |  |  |  |  |  
 system_mtime | date-time |  | true |  |  |  |  |  |  
 create_time | date-time |  | true |  |  |  |  |  |  
 repository | object |  | true |  |  |  |  |  | ref 
 locations | array |  |  | {"type"=>"JSONModel(:location) uri"} |  |  |  |  |  
 coordinate_1_range | object |  |  |  |  |  | error |  |  
 coordinate_2_range | object |  |  |  |  |  |  |  |  
 coordinate_3_range | object |  |  |  |  |  |  |  |  




##JSONModel(:location_batch_update)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "location",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "title": {
      "type": "string",
      "readonly": true
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "building": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "ifmissing": null
    },
    "floor": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "room": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "area": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "barcode": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "classification": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_1_label": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_1_indicator": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_2_label": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_2_indicator": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_3_label": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "coordinate_3_indicator": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "temporary": {
      "type": "string",
      "dynamic_enum": "location_temporary"
    },
    "location_profile": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:location_profile) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "owner_repo": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "functions": {
      "type": "array",
      "items": {
        "type": "JSONModel(:location_function) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "record_uris": {
      "type": "array",
      "items": {
        "type": "JSONModel(:location) uri"
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | readonly | items | maxLength | minLength | ifmissing | dynamic_enum | subtype  
 ----- | ---- | -------- | -------- | ----- | --------- | --------- | --------- | ------------ | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 title | string |  | true |  |  |  |  |  |  
 external_ids | array |  |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  
 building | string |  |  |  | 255 | 1 |  |  |  
 floor | string |  |  |  | 255 |  |  |  |  
 room | string |  |  |  | 255 |  |  |  |  
 area | string |  |  |  | 255 |  |  |  |  
 barcode | string |  |  |  | 255 |  |  |  |  
 classification | string |  |  |  | 255 |  |  |  |  
 coordinate_1_label | string |  |  |  | 255 |  |  |  |  
 coordinate_1_indicator | string |  |  |  | 255 |  |  |  |  
 coordinate_2_label | string |  |  |  | 255 |  |  |  |  
 coordinate_2_indicator | string |  |  |  | 255 |  |  |  |  
 coordinate_3_label | string |  |  |  | 255 |  |  |  |  
 coordinate_3_indicator | string |  |  |  | 255 |  |  |  |  
 temporary | string |  |  |  |  |  |  | location_temporary |  
 location_profile | object |  |  |  |  |  |  |  | ref 
 owner_repo | object |  |  |  |  |  |  |  | ref 
 functions | array |  |  | {"type"=>"JSONModel(:location_function) object"} |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  | true |  |  |  |  |  |  
 last_modified_by | string |  | true |  |  |  |  |  |  
 user_mtime | date-time |  | true |  |  |  |  |  |  
 system_mtime | date-time |  | true |  |  |  |  |  |  
 create_time | date-time |  | true |  |  |  |  |  |  
 repository | object |  | true |  |  |  |  |  | ref 
 record_uris | array |  |  | {"type"=>"JSONModel(:location) uri"} |  |  |  |  |  




##JSONModel(:location_function)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "location_function_type": {
      "type": "string",
      "dynamic_enum": "location_function_type"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | dynamic_enum | required | ifmissing | readonly | subtype  
 ----- | ---- | ------------ | -------- | --------- | -------- | ------- |  
 location_function_type | string | location_function_type |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:location_profile)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/location_profiles",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "name": {
      "type": "string",
      "ifmissing": "error"
    },
    "display_string": {
      "type": "string",
      "readonly": true
    },
    "dimension_units": {
      "type": "string",
      "dynamic_enum": "dimension_units"
    },
    "height": {
      "type": "string",
      "required": false
    },
    "width": {
      "type": "string",
      "required": false
    },
    "depth": {
      "type": "string",
      "required": false
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_location_profile"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | readonly | dynamic_enum | subtype  
 ----- | ---- | -------- | --------- | -------- | ------------ | ------- |  
 uri | string |  |  |  |  |  
 name | string |  | error |  |  |  
 display_string | string |  |  | true |  |  
 dimension_units | string |  |  |  | dimension_units |  
 height | string |  |  |  |  |  
 width | string |  |  |  |  |  
 depth | string |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  
 created_by | string |  |  | true |  |  
 last_modified_by | string |  |  | true |  |  
 user_mtime | date-time |  |  | true |  |  
 system_mtime | date-time |  |  | true |  |  
 create_time | date-time |  |  | true |  |  
 repository | object |  |  | true |  | ref 




##JSONModel(:merge_request)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "uri": "/merge_requests/:record_type",
  "version": 1,
  "type": "object",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "target": {
      "type": "object",
      "ifmissing": "error",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": [
            {
              "type": "JSONModel(:subject) uri"
            },
            {
              "type": "JSONModel(:agent_person) uri"
            },
            {
              "type": "JSONModel(:agent_corporate_entity) uri"
            },
            {
              "type": "JSONModel(:agent_software) uri"
            },
            {
              "type": "JSONModel(:agent_family) uri"
            },
            {
              "type": "JSONModel(:resource) uri"
            },
            {
              "type": "JSONModel(:digital_object) uri"
            }
          ],
          "ifmissing": "error"
        }
      }
    },
    "victims": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              {
                "type": "JSONModel(:subject) uri"
              },
              {
                "type": "JSONModel(:agent_person) uri"
              },
              {
                "type": "JSONModel(:agent_corporate_entity) uri"
              },
              {
                "type": "JSONModel(:agent_software) uri"
              },
              {
                "type": "JSONModel(:agent_family) uri"
              },
              {
                "type": "JSONModel(:resource) uri"
              },
              {
                "type": "JSONModel(:digital_object) uri"
              }
            ],
            "ifmissing": "error"
          }
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | subtype | minItems | items | readonly  
 ----- | ---- | -------- | --------- | ------- | -------- | ----- | -------- |  
 uri | string |  |  |  |  |  |  
 target | object |  | error | ref |  |  |  
 victims | array |  |  |  | 1 | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>[{"type"=>"JSONModel(:subject) uri"}, {"type"=>"JSONModel(:agent_person) uri"}, {"type"=>"JSONModel(:agent_corporate_entity) uri"}, {"type"=>"JSONModel(:agent_software) uri"}, {"type"=>"JSONModel(:agent_family) uri"}, {"type"=>"JSONModel(:resource) uri"}, {"type"=>"JSONModel(:digital_object) uri"}], "ifmissing"=>"error"}}} |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  
 created_by | string |  |  |  |  |  | true 
 last_modified_by | string |  |  |  |  |  | true 
 user_mtime | date-time |  |  |  |  |  | true 
 system_mtime | date-time |  |  |  |  |  | true 
 create_time | date-time |  |  |  |  |  | true 
 repository | object |  |  | ref |  |  | true 




##JSONModel(:name_corporate_entity)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "parent": "abstract_name",
  "type": "object",
  "properties": {
    "authority_id": {
      "type": "string",
      "maxLength": 255
    },
    "dates": {
      "type": "string",
      "maxLength": 255
    },
    "use_dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "qualifier": {
      "type": "string",
      "maxLength": 255
    },
    "source": {
      "type": "string",
      "dynamic_enum": "name_source"
    },
    "rules": {
      "type": "string",
      "dynamic_enum": "name_rule"
    },
    "authorized": {
      "type": "boolean",
      "default": false
    },
    "is_display_name": {
      "type": "boolean",
      "default": false
    },
    "sort_name": {
      "type": "string",
      "maxLength": 255
    },
    "sort_name_auto_generate": {
      "type": "boolean",
      "default": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "primary_name": {
      "type": "string",
      "maxLength": 65000,
      "ifmissing": "error"
    },
    "subordinate_name_1": {
      "type": "string",
      "maxLength": 65000
    },
    "subordinate_name_2": {
      "type": "string",
      "maxLength": 65000
    },
    "number": {
      "type": "string",
      "maxLength": 255
    }
  },
  "validations": [
    [
      "error",
      "name_corporate_entity_check_source"
    ],
    [
      "error",
      "name_corporate_entity_check_name"
    ],
    [
      "warning",
      "name_corporate_entity_check_authority_id"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | items | dynamic_enum | default | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | ----- | ------------ | ------- | -------- | --------- | -------- | ------- |  
 authority_id | string | 255 |  |  |  |  |  |  |  
 dates | string | 255 |  |  |  |  |  |  |  
 use_dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  
 qualifier | string | 255 |  |  |  |  |  |  |  
 source | string |  |  | name_source |  |  |  |  |  
 rules | string |  |  | name_rule |  |  |  |  |  
 authorized | boolean |  |  |  |  |  |  |  |  
 is_display_name | boolean |  |  |  |  |  |  |  |  
 sort_name | string | 255 |  |  |  |  |  |  |  
 sort_name_auto_generate | boolean |  |  |  | true |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 
 primary_name | string | 65000 |  |  |  |  | error |  |  
 subordinate_name_1 | string | 65000 |  |  |  |  |  |  |  
 subordinate_name_2 | string | 65000 |  |  |  |  |  |  |  
 number | string | 255 |  |  |  |  |  |  |  




##JSONModel(:name_family)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "parent": "abstract_name",
  "type": "object",
  "properties": {
    "authority_id": {
      "type": "string",
      "maxLength": 255
    },
    "dates": {
      "type": "string",
      "maxLength": 255
    },
    "use_dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "qualifier": {
      "type": "string",
      "maxLength": 255
    },
    "source": {
      "type": "string",
      "dynamic_enum": "name_source"
    },
    "rules": {
      "type": "string",
      "dynamic_enum": "name_rule"
    },
    "authorized": {
      "type": "boolean",
      "default": false
    },
    "is_display_name": {
      "type": "boolean",
      "default": false
    },
    "sort_name": {
      "type": "string",
      "maxLength": 255
    },
    "sort_name_auto_generate": {
      "type": "boolean",
      "default": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "family_name": {
      "type": "string",
      "maxLength": 65000,
      "ifmissing": "error"
    },
    "prefix": {
      "type": "string",
      "maxLength": 65000
    }
  },
  "validations": [
    [
      "error",
      "name_family_check_source"
    ],
    [
      "error",
      "name_family_check_name"
    ],
    [
      "warning",
      "name_family_check_authority_id"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | items | dynamic_enum | default | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | ----- | ------------ | ------- | -------- | --------- | -------- | ------- |  
 authority_id | string | 255 |  |  |  |  |  |  |  
 dates | string | 255 |  |  |  |  |  |  |  
 use_dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  
 qualifier | string | 255 |  |  |  |  |  |  |  
 source | string |  |  | name_source |  |  |  |  |  
 rules | string |  |  | name_rule |  |  |  |  |  
 authorized | boolean |  |  |  |  |  |  |  |  
 is_display_name | boolean |  |  |  |  |  |  |  |  
 sort_name | string | 255 |  |  |  |  |  |  |  
 sort_name_auto_generate | boolean |  |  |  | true |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 
 family_name | string | 65000 |  |  |  |  | error |  |  
 prefix | string | 65000 |  |  |  |  |  |  |  




##JSONModel(:name_form)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/agents/:agent_id/name_forms",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "kind": {
      "type": "string",
      "ifmissing": "error"
    },
    "sort_name": {
      "type": "string",
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | readonly | subtype  
 ----- | ---- | -------- | --------- | -------- | ------- |  
 uri | string |  |  |  |  
 kind | string |  | error |  |  
 sort_name | string |  | error |  |  
 lock_version | integer | string |  |  |  |  
 jsonmodel_type | string |  | error |  |  
 created_by | string |  |  | true |  
 last_modified_by | string |  |  | true |  
 user_mtime | date-time |  |  | true |  
 system_mtime | date-time |  |  | true |  
 create_time | date-time |  |  | true |  
 repository | object |  |  | true | ref 




##JSONModel(:name_person)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "parent": "abstract_name",
  "type": "object",
  "properties": {
    "authority_id": {
      "type": "string",
      "maxLength": 255
    },
    "dates": {
      "type": "string",
      "maxLength": 255
    },
    "use_dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "qualifier": {
      "type": "string",
      "maxLength": 255
    },
    "source": {
      "type": "string",
      "dynamic_enum": "name_source"
    },
    "rules": {
      "type": "string",
      "dynamic_enum": "name_rule"
    },
    "authorized": {
      "type": "boolean",
      "default": false
    },
    "is_display_name": {
      "type": "boolean",
      "default": false
    },
    "sort_name": {
      "type": "string",
      "maxLength": 255
    },
    "sort_name_auto_generate": {
      "type": "boolean",
      "default": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "primary_name": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error"
    },
    "title": {
      "type": "string",
      "maxLength": 16384
    },
    "name_order": {
      "type": "string",
      "ifmissing": "error",
      "dynamic_enum": "name_person_name_order"
    },
    "prefix": {
      "type": "string",
      "maxLength": 65000
    },
    "rest_of_name": {
      "type": "string",
      "maxLength": 65000
    },
    "suffix": {
      "type": "string",
      "maxLength": 65000
    },
    "fuller_form": {
      "type": "string",
      "maxLength": 65000
    },
    "number": {
      "type": "string",
      "maxLength": 255
    }
  },
  "validations": [
    [
      "error",
      "name_person_check_source"
    ],
    [
      "error",
      "name_person_check_name"
    ],
    [
      "warning",
      "name_person_check_authority_id"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | items | dynamic_enum | default | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | ----- | ------------ | ------- | -------- | --------- | -------- | ------- |  
 authority_id | string | 255 |  |  |  |  |  |  |  
 dates | string | 255 |  |  |  |  |  |  |  
 use_dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  
 qualifier | string | 255 |  |  |  |  |  |  |  
 source | string |  |  | name_source |  |  |  |  |  
 rules | string |  |  | name_rule |  |  |  |  |  
 authorized | boolean |  |  |  |  |  |  |  |  
 is_display_name | boolean |  |  |  |  |  |  |  |  
 sort_name | string | 255 |  |  |  |  |  |  |  
 sort_name_auto_generate | boolean |  |  |  | true |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 
 primary_name | string | 255 |  |  |  |  | error |  |  
 title | string | 16384 |  |  |  |  |  |  |  
 name_order | string |  |  | name_person_name_order |  |  | error |  |  
 prefix | string | 65000 |  |  |  |  |  |  |  
 rest_of_name | string | 65000 |  |  |  |  |  |  |  
 suffix | string | 65000 |  |  |  |  |  |  |  
 fuller_form | string | 65000 |  |  |  |  |  |  |  
 number | string | 255 |  |  |  |  |  |  |  




##JSONModel(:name_software)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "parent": "abstract_name",
  "type": "object",
  "properties": {
    "authority_id": {
      "type": "string",
      "maxLength": 255
    },
    "dates": {
      "type": "string",
      "maxLength": 255
    },
    "use_dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      }
    },
    "qualifier": {
      "type": "string",
      "maxLength": 255
    },
    "source": {
      "type": "string",
      "dynamic_enum": "name_source"
    },
    "rules": {
      "type": "string",
      "dynamic_enum": "name_rule"
    },
    "authorized": {
      "type": "boolean",
      "default": false
    },
    "is_display_name": {
      "type": "boolean",
      "default": false
    },
    "sort_name": {
      "type": "string",
      "maxLength": 255
    },
    "sort_name_auto_generate": {
      "type": "boolean",
      "default": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "software_name": {
      "type": "string",
      "maxLength": 65000,
      "ifmissing": "error"
    },
    "version": {
      "type": "string",
      "maxLength": 65000
    },
    "manufacturer": {
      "type": "string",
      "maxLength": 65000
    }
  },
  "validations": [
    [
      "error",
      "name_software_check_source"
    ],
    [
      "error",
      "name_software_check_name"
    ],
    [
      "warning",
      "name_software_check_authority_id"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | items | dynamic_enum | default | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | ----- | ------------ | ------- | -------- | --------- | -------- | ------- |  
 authority_id | string | 255 |  |  |  |  |  |  |  
 dates | string | 255 |  |  |  |  |  |  |  
 use_dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  |  |  |  |  
 qualifier | string | 255 |  |  |  |  |  |  |  
 source | string |  |  | name_source |  |  |  |  |  
 rules | string |  |  | name_rule |  |  |  |  |  
 authorized | boolean |  |  |  |  |  |  |  |  
 is_display_name | boolean |  |  |  |  |  |  |  |  
 sort_name | string | 255 |  |  |  |  |  |  |  
 sort_name_auto_generate | boolean |  |  |  | true |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 
 software_name | string | 65000 |  |  |  |  | error |  |  
 version | string | 65000 |  |  |  |  |  |  |  
 manufacturer | string | 65000 |  |  |  |  |  |  |  




##JSONModel(:note_abstract)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_note",
  "properties": {
    "label": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean"
    },
    "persistent_id": {
      "type": "string",
      "maxLength": 255
    },
    "ingest_problem": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "content": {
      "type": "array",
      "items": {
        "type": "string",
        "maxLength": 65000
      },
      "minItems": 1,
      "ifmissing": "error"
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | items | minItems  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ----- | -------- |  
 label | string | 65000 |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 persistent_id | string | 255 |  |  |  |  |  |  
 ingest_problem | string | 65000 |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  
 created_by | string |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  | true |  |  |  
 create_time | date-time |  |  |  | true |  |  |  
 repository | object |  |  |  | true | ref |  |  
 content | array |  |  | error |  |  | {"type"=>"string", "maxLength"=>65000} | 1 




##JSONModel(:note_bibliography)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_note",
  "properties": {
    "label": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean"
    },
    "persistent_id": {
      "type": "string",
      "maxLength": 255
    },
    "ingest_problem": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "content": {
      "type": "array",
      "items": {
        "type": "string",
        "maxLength": 65000
      },
      "minItems": 0,
      "ifmissing": null
    },
    "type": {
      "type": "string",
      "readonly": true,
      "dynamic_enum": "note_bibliography_type"
    },
    "items": {
      "type": "array",
      "items": {
        "type": "string",
        "maxLength": 65000
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | items | minItems | dynamic_enum  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ----- | -------- | ------------ |  
 label | string | 65000 |  |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  
 persistent_id | string | 255 |  |  |  |  |  |  |  
 ingest_problem | string | 65000 |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  | true |  |  |  |  
 last_modified_by | string |  |  |  | true |  |  |  |  
 user_mtime | date-time |  |  |  | true |  |  |  |  
 system_mtime | date-time |  |  |  | true |  |  |  |  
 create_time | date-time |  |  |  | true |  |  |  |  
 repository | object |  |  |  | true | ref |  |  |  
 content | array |  |  |  |  |  | {"type"=>"string", "maxLength"=>65000} | 0 |  
 type | string |  |  |  | true |  |  |  | note_bibliography_type 
 items | array |  |  |  |  |  | {"type"=>"string", "maxLength"=>65000} |  |  




##JSONModel(:note_bioghist)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_note",
  "properties": {
    "label": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean"
    },
    "persistent_id": {
      "type": "string",
      "maxLength": 255
    },
    "ingest_problem": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "subnotes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_abstract) object"
          },
          {
            "type": "JSONModel(:note_chronology) object"
          },
          {
            "type": "JSONModel(:note_citation) object"
          },
          {
            "type": "JSONModel(:note_orderedlist) object"
          },
          {
            "type": "JSONModel(:note_definedlist) object"
          },
          {
            "type": "JSONModel(:note_text) object"
          },
          {
            "type": "JSONModel(:note_outline) object"
          }
        ]
      }
    }
  },
  "validations": [
    [
      "error",
      "note_bioghist_check_at_least_one_subnote"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | items  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ----- |  
 label | string | 65000 |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  
 persistent_id | string | 255 |  |  |  |  |  
 ingest_problem | string | 65000 |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  
 created_by | string |  |  |  | true |  |  
 last_modified_by | string |  |  |  | true |  |  
 user_mtime | date-time |  |  |  | true |  |  
 system_mtime | date-time |  |  |  | true |  |  
 create_time | date-time |  |  |  | true |  |  
 repository | object |  |  |  | true | ref |  
 subnotes | array |  |  |  |  |  | {"type"=>[{"type"=>"JSONModel(:note_abstract) object"}, {"type"=>"JSONModel(:note_chronology) object"}, {"type"=>"JSONModel(:note_citation) object"}, {"type"=>"JSONModel(:note_orderedlist) object"}, {"type"=>"JSONModel(:note_definedlist) object"}, {"type"=>"JSONModel(:note_text) object"}, {"type"=>"JSONModel(:note_outline) object"}]} 




##JSONModel(:note_chronology)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "title": {
      "type": "string",
      "maxLength": 16384
    },
    "publish": {
      "type": "boolean"
    },
    "items": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "event_date": {
            "type": "string",
            "maxLength": 255
          },
          "events": {
            "type": "array",
            "items": {
              "type": "string",
              "maxLength": 65000
            }
          }
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | items | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | ----- | -------- | --------- | -------- | ------- |  
 title | string | 16384 |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  
 items | array |  | {"type"=>"object", "properties"=>{"event_date"=>{"type"=>"string", "maxLength"=>255}, "events"=>{"type"=>"array", "items"=>{"type"=>"string", "maxLength"=>65000}}}} |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  | error |  |  
 created_by | string |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  | true |  
 create_time | date-time |  |  |  |  | true |  
 repository | object |  |  |  |  | true | ref 




##JSONModel(:note_citation)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_note",
  "properties": {
    "label": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean"
    },
    "persistent_id": {
      "type": "string",
      "maxLength": 255
    },
    "ingest_problem": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "content": {
      "type": "array",
      "items": {
        "type": "string",
        "maxLength": 65000
      },
      "minItems": 1,
      "ifmissing": "error"
    },
    "xlink": {
      "type": "object",
      "properties": {
        "actuate": {
          "type": "string",
          "maxLength": 65000
        },
        "arcrole": {
          "type": "string",
          "maxLength": 65000
        },
        "href": {
          "type": "string",
          "maxLength": 65000
        },
        "role": {
          "type": "string",
          "maxLength": 65000
        },
        "show": {
          "type": "string",
          "maxLength": 65000
        },
        "title": {
          "type": "string",
          "maxLength": 16384
        },
        "type": {
          "type": "string",
          "maxLength": 65000
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | items | minItems  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ----- | -------- |  
 label | string | 65000 |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 persistent_id | string | 255 |  |  |  |  |  |  
 ingest_problem | string | 65000 |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  
 created_by | string |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  | true |  |  |  
 create_time | date-time |  |  |  | true |  |  |  
 repository | object |  |  |  | true | ref |  |  
 content | array |  |  | error |  |  | {"type"=>"string", "maxLength"=>65000} | 1 
 xlink | object |  |  |  |  |  |  |  




##JSONModel(:note_definedlist)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "title": {
      "type": "string",
      "maxLength": 16384
    },
    "publish": {
      "type": "boolean"
    },
    "items": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "label": {
            "type": "string",
            "ifmissing": "error",
            "maxLength": 65000
          },
          "value": {
            "type": "string",
            "ifmissing": "error",
            "maxLength": 65000
          }
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | items | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | ----- | -------- | --------- | -------- | ------- |  
 title | string | 16384 |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  
 items | array |  | {"type"=>"object", "properties"=>{"label"=>{"type"=>"string", "ifmissing"=>"error", "maxLength"=>65000}, "value"=>{"type"=>"string", "ifmissing"=>"error", "maxLength"=>65000}}} |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  | error |  |  
 created_by | string |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  | true |  
 create_time | date-time |  |  |  |  | true |  
 repository | object |  |  |  |  | true | ref 




##JSONModel(:note_digital_object)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_note",
  "properties": {
    "label": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean"
    },
    "persistent_id": {
      "type": "string",
      "maxLength": 255
    },
    "ingest_problem": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "content": {
      "type": "array",
      "items": {
        "type": "string",
        "maxLength": 65000
      },
      "minItems": 1,
      "ifmissing": "error"
    },
    "type": {
      "type": "string",
      "ifmissing": "error",
      "dynamic_enum": "note_digital_object_type"
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | items | minItems | dynamic_enum  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ----- | -------- | ------------ |  
 label | string | 65000 |  |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  
 persistent_id | string | 255 |  |  |  |  |  |  |  
 ingest_problem | string | 65000 |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  | true |  |  |  |  
 last_modified_by | string |  |  |  | true |  |  |  |  
 user_mtime | date-time |  |  |  | true |  |  |  |  
 system_mtime | date-time |  |  |  | true |  |  |  |  
 create_time | date-time |  |  |  | true |  |  |  |  
 repository | object |  |  |  | true | ref |  |  |  
 content | array |  |  | error |  |  | {"type"=>"string", "maxLength"=>65000} | 1 |  
 type | string |  |  | error |  |  |  |  | note_digital_object_type 




##JSONModel(:note_index)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_note",
  "properties": {
    "label": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean"
    },
    "persistent_id": {
      "type": "string",
      "maxLength": 255
    },
    "ingest_problem": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "content": {
      "type": "array",
      "items": {
        "type": "string",
        "maxLength": 65000
      },
      "minItems": 0,
      "ifmissing": null
    },
    "type": {
      "type": "string",
      "readonly": true,
      "dynamic_enum": "note_index_type"
    },
    "items": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_index_item) object"
          }
        ]
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | items | minItems | dynamic_enum  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ----- | -------- | ------------ |  
 label | string | 65000 |  |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  
 persistent_id | string | 255 |  |  |  |  |  |  |  
 ingest_problem | string | 65000 |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  | true |  |  |  |  
 last_modified_by | string |  |  |  | true |  |  |  |  
 user_mtime | date-time |  |  |  | true |  |  |  |  
 system_mtime | date-time |  |  |  | true |  |  |  |  
 create_time | date-time |  |  |  | true |  |  |  |  
 repository | object |  |  |  | true | ref |  |  |  
 content | array |  |  |  |  |  | {"type"=>"string", "maxLength"=>65000} | 0 |  
 type | string |  |  |  | true |  |  |  | note_index_type 
 items | array |  |  |  |  |  | {"type"=>[{"type"=>"JSONModel(:note_index_item) object"}]} |  |  




##JSONModel(:note_index_item)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "value": {
      "type": "string",
      "ifmissing": "error",
      "maxLength": 65000
    },
    "type": {
      "type": "string",
      "ifmissing": "error",
      "dynamic_enum": "note_index_item_type"
    },
    "reference": {
      "type": "string",
      "maxLength": 65000
    },
    "reference_text": {
      "type": "string",
      "maxLength": 65000
    },
    "reference_ref": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "string",
          "readonly": true
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | ifmissing | maxLength | dynamic_enum | subtype | required | readonly  
 ----- | ---- | --------- | --------- | ------------ | ------- | -------- | -------- |  
 value | string | error | 65000 |  |  |  |  
 type | string | error |  | note_index_item_type |  |  |  
 reference | string |  | 65000 |  |  |  |  
 reference_text | string |  | 65000 |  |  |  |  
 reference_ref | object |  |  |  | ref |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string | error |  |  |  |  |  
 created_by | string |  |  |  |  |  | true 
 last_modified_by | string |  |  |  |  |  | true 
 user_mtime | date-time |  |  |  |  |  | true 
 system_mtime | date-time |  |  |  |  |  | true 
 create_time | date-time |  |  |  |  |  | true 
 repository | object |  |  |  | ref |  | true 




##JSONModel(:note_multipart)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_note",
  "properties": {
    "label": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean"
    },
    "persistent_id": {
      "type": "string",
      "maxLength": 255
    },
    "ingest_problem": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "type": {
      "type": "string",
      "ifmissing": "error",
      "dynamic_enum": "note_multipart_type"
    },
    "rights_restriction": {
      "type": "JSONModel(:rights_restriction) object"
    },
    "subnotes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_chronology) object"
          },
          {
            "type": "JSONModel(:note_orderedlist) object"
          },
          {
            "type": "JSONModel(:note_definedlist) object"
          },
          {
            "type": "JSONModel(:note_text) object"
          }
        ]
      }
    }
  },
  "validations": [
    [
      "error",
      "note_multipart_check_at_least_one_subnote"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | dynamic_enum | items  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ------------ | ----- |  
 label | string | 65000 |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 persistent_id | string | 255 |  |  |  |  |  |  
 ingest_problem | string | 65000 |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  
 created_by | string |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  | true |  |  |  
 create_time | date-time |  |  |  | true |  |  |  
 repository | object |  |  |  | true | ref |  |  
 type | string |  |  | error |  |  | note_multipart_type |  
 rights_restriction | JSONModel(:rights_restriction) object |  |  |  |  |  |  |  
 subnotes | array |  |  |  |  |  |  | {"type"=>[{"type"=>"JSONModel(:note_chronology) object"}, {"type"=>"JSONModel(:note_orderedlist) object"}, {"type"=>"JSONModel(:note_definedlist) object"}, {"type"=>"JSONModel(:note_text) object"}]} 




##JSONModel(:note_orderedlist)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "title": {
      "type": "string",
      "maxLength": 16384
    },
    "publish": {
      "type": "boolean"
    },
    "enumeration": {
      "type": "string",
      "dynamic_enum": "note_orderedlist_enumeration"
    },
    "items": {
      "type": "array",
      "items": {
        "type": "string",
        "maxLength": 65000
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | dynamic_enum | items | required | ifmissing | readonly | subtype  
 ----- | ---- | --------- | ------------ | ----- | -------- | --------- | -------- | ------- |  
 title | string | 16384 |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  
 enumeration | string |  | note_orderedlist_enumeration |  |  |  |  |  
 items | array |  |  | {"type"=>"string", "maxLength"=>65000} |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  | true | ref 




##JSONModel(:note_outline)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "publish": {
      "type": "boolean"
    },
    "levels": {
      "type": "array",
      "items": {
        "type": "JSONModel(:note_outline_level) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | items | required | ifmissing | readonly | subtype  
 ----- | ---- | ----- | -------- | --------- | -------- | ------- |  
 publish | boolean |  |  |  |  |  
 levels | array | {"type"=>"JSONModel(:note_outline_level) object"} |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:note_outline_level)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "string"
          },
          {
            "type": "JSONModel(:note_outline_level) object"
          }
        ]
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | items | required | ifmissing | readonly | subtype  
 ----- | ---- | ----- | -------- | --------- | -------- | ------- |  
 items | array | {"type"=>[{"type"=>"string"}, {"type"=>"JSONModel(:note_outline_level) object"}]} |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:note_singlepart)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_note",
  "properties": {
    "label": {
      "type": "string",
      "maxLength": 65000
    },
    "publish": {
      "type": "boolean"
    },
    "persistent_id": {
      "type": "string",
      "maxLength": 255
    },
    "ingest_problem": {
      "type": "string",
      "maxLength": 65000
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "content": {
      "type": "array",
      "items": {
        "type": "string",
        "maxLength": 65000
      },
      "minItems": 1,
      "ifmissing": "error"
    },
    "type": {
      "type": "string",
      "ifmissing": "error",
      "dynamic_enum": "note_singlepart_type"
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | required | ifmissing | readonly | subtype | items | minItems | dynamic_enum  
 ----- | ---- | --------- | -------- | --------- | -------- | ------- | ----- | -------- | ------------ |  
 label | string | 65000 |  |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  
 persistent_id | string | 255 |  |  |  |  |  |  |  
 ingest_problem | string | 65000 |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  | true |  |  |  |  
 last_modified_by | string |  |  |  | true |  |  |  |  
 user_mtime | date-time |  |  |  | true |  |  |  |  
 system_mtime | date-time |  |  |  | true |  |  |  |  
 create_time | date-time |  |  |  | true |  |  |  |  
 repository | object |  |  |  | true | ref |  |  |  
 content | array |  |  | error |  |  | {"type"=>"string", "maxLength"=>65000} | 1 |  
 type | string |  |  | error |  |  |  |  | note_singlepart_type 




##JSONModel(:note_text)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "content": {
      "type": "string",
      "maxLength": 65000,
      "ifmissing": "error"
    },
    "publish": {
      "type": "boolean"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | maxLength | ifmissing | required | readonly | subtype  
 ----- | ---- | --------- | --------- | -------- | -------- | ------- |  
 content | string | 65000 | error |  |  |  
 publish | boolean |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:permission)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/permissions",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "permission_code": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error",
      "minLength": 1
    },
    "description": {
      "type": "string",
      "maxLength": 65000,
      "ifmissing": "error",
      "minLength": 1
    },
    "level": {
      "type": "string",
      "ifmissing": "error",
      "enum": [
        "repository",
        "global"
      ]
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | minLength | enum | readonly | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ---- | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  
 permission_code | string |  | 255 | error | 1 |  |  |  
 description | string |  | 65000 | error | 1 |  |  |  
 level | string |  |  | error |  | repository | global |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  
 created_by | string |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  | true | ref 




##JSONModel(:preference)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/preferences",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "user_id": {
      "type": "integer"
    },
    "defaults": {
      "type": "JSONModel(:defaults) object"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | readonly | subtype  
 ----- | ---- | -------- | --------- | -------- | ------- |  
 uri | string |  |  |  |  
 user_id | integer |  |  |  |  
 defaults | JSONModel(:defaults) object |  |  |  |  
 lock_version | integer | string |  |  |  |  
 jsonmodel_type | string |  | error |  |  
 created_by | string |  |  | true |  
 last_modified_by | string |  |  | true |  
 user_mtime | date-time |  |  | true |  
 system_mtime | date-time |  |  | true |  
 create_time | date-time |  |  | true |  
 repository | object |  |  | true | ref 




##JSONModel(:print_to_pdf_job)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "source": {
      "type": "string",
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | ifmissing | required | readonly | subtype  
 ----- | ---- | --------- | -------- | -------- | ------- |  
 source | string | error |  |  |  
 lock_version | integer | string |  |  |  |  
 jsonmodel_type | string | error |  |  |  
 created_by | string |  |  | true |  
 last_modified_by | string |  |  | true |  
 user_mtime | date-time |  |  | true |  
 system_mtime | date-time |  |  | true |  
 create_time | date-time |  |  | true |  
 repository | object |  |  | true | ref 




##JSONModel(:rde_template)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/rde_templates",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "name": {
      "type": "string",
      "ifmissing": "error"
    },
    "record_type": {
      "type": "string",
      "ifmissing": "error",
      "enum": [
        "archival_object",
        "digital_object_component"
      ]
    },
    "order": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "visible": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "defaults": {
      "type": "object"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | enum | items | readonly | subtype  
 ----- | ---- | -------- | --------- | ---- | ----- | -------- | ------- |  
 uri | string |  |  |  |  |  |  
 name | string |  | error |  |  |  |  
 record_type | string |  | error | archival_object | digital_object_component |  |  |  
 order | array |  |  |  | {"type"=>"string"} |  |  
 visible | array |  |  |  | {"type"=>"string"} |  |  
 defaults | object |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  
 created_by | string |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  | true |  
 create_time | date-time |  |  |  |  | true |  
 repository | object |  |  |  |  | true | ref 




##JSONModel(:report_job)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "report_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "format": {
      "type": "string",
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | ifmissing | required | readonly | subtype  
 ----- | ---- | --------- | -------- | -------- | ------- |  
 report_type | string | error |  |  |  
 format | string | error |  |  |  
 lock_version | integer | string |  |  |  |  
 jsonmodel_type | string | error |  |  |  
 created_by | string |  |  | true |  
 last_modified_by | string |  |  | true |  
 user_mtime | date-time |  |  | true |  
 system_mtime | date-time |  |  | true |  
 create_time | date-time |  |  | true |  
 repository | object |  |  | true | ref 




##JSONModel(:repository)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "repo_code": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error",
      "minLength": 1
    },
    "name": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error",
      "default": ""
    },
    "org_code": {
      "type": "string",
      "maxLength": 255
    },
    "country": {
      "type": "string",
      "required": false,
      "dynamic_enum": "country_iso_3166"
    },
    "parent_institution_name": {
      "type": "string",
      "maxLength": 255
    },
    "url": {
      "type": "string",
      "maxLength": 255,
      "pattern": "\\Ahttps?:\\/\\/[\\S]+\\z"
    },
    "image_url": {
      "type": "string",
      "maxLength": 255,
      "pattern": "\\Ahttps?:\\/\\/[\\S]+\\z"
    },
    "contact_persons": {
      "type": "string",
      "maxLength": 65000
    },
    "display_string": {
      "type": "string",
      "readonly": true
    },
    "agent_representation": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:agent_corporate_entity) uri",
          "ifmissing": "error",
          "readonly": "true"
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | minLength | default | dynamic_enum | pattern | readonly | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ------- | ------------ | ------- | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  |  
 repo_code | string |  | 255 | error | 1 |  |  |  |  |  
 name | string |  | 255 | error |  |  |  |  |  |  
 org_code | string |  | 255 |  |  |  |  |  |  |  
 country | string |  |  |  |  |  | country_iso_3166 |  |  |  
 parent_institution_name | string |  | 255 |  |  |  |  |  |  |  
 url | string |  | 255 |  |  |  |  | \Ahttps?:\/\/[\S]+\z |  |  
 image_url | string |  | 255 |  |  |  |  | \Ahttps?:\/\/[\S]+\z |  |  
 contact_persons | string |  | 65000 |  |  |  |  |  |  |  
 display_string | string |  |  |  |  |  |  |  | true |  
 agent_representation | object |  |  |  |  |  |  |  |  | ref 
 lock_version | integer | string |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  |  
 created_by | string |  |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  |  | true | ref 




##JSONModel(:repository_with_agent)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/with_agent",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "repository": {
      "type": "JSONModel(:repository) object",
      "ifmissing": "error"
    },
    "agent_representation": {
      "type": "JSONModel(:agent_corporate_entity) object"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | readonly  
 ----- | ---- | -------- | --------- | -------- |  
 uri | string |  |  |  
 repository | JSONModel(:repository) object |  | error |  
 agent_representation | JSONModel(:agent_corporate_entity) object |  |  |  
 lock_version | integer | string |  |  |  
 jsonmodel_type | string |  | error |  
 created_by | string |  |  | true 
 last_modified_by | string |  |  | true 
 user_mtime | date-time |  |  | true 
 system_mtime | date-time |  |  | true 
 create_time | date-time |  |  | true 




##JSONModel(:resource)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "parent": "abstract_archival_object",
  "uri": "/repositories/:repo_id/resources",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 16384,
      "ifmissing": "error"
    },
    "language": {
      "type": "string",
      "dynamic_enum": "language_iso639_2",
      "ifmissing": "warn"
    },
    "publish": {
      "type": "boolean"
    },
    "subjects": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:subject) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "linked_events": {
      "type": "array",
      "readonly": "true",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:event) uri",
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "extents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:extent) object"
      },
      "ifmissing": "error",
      "minItems": 1
    },
    "dates": {
      "type": "array",
      "items": {
        "type": "JSONModel(:date) object"
      },
      "ifmissing": "error",
      "minItems": 1
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "rights_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:rights_statement) object"
      }
    },
    "linked_agents": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "role": {
            "type": "string",
            "dynamic_enum": "linked_agent_role",
            "ifmissing": "error"
          },
          "terms": {
            "type": "array",
            "items": {
              "type": "JSONModel(:term) uri_or_object"
            }
          },
          "relator": {
            "type": "string",
            "dynamic_enum": "linked_agent_archival_record_relators"
          },
          "title": {
            "type": "string"
          },
          "ref": {
            "type": [
              {
                "type": "JSONModel(:agent_corporate_entity) uri"
              },
              {
                "type": "JSONModel(:agent_family) uri"
              },
              {
                "type": "JSONModel(:agent_person) uri"
              },
              {
                "type": "JSONModel(:agent_software) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "suppressed": {
      "type": "boolean",
      "readonly": "true"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "id_0": {
      "type": "string",
      "ifmissing": "error",
      "maxLength": 255
    },
    "id_1": {
      "type": "string",
      "maxLength": 255
    },
    "id_2": {
      "type": "string",
      "maxLength": 255
    },
    "id_3": {
      "type": "string",
      "maxLength": 255
    },
    "level": {
      "type": "string",
      "ifmissing": "error",
      "dynamic_enum": "archival_record_level"
    },
    "other_level": {
      "type": "string",
      "maxLength": 255
    },
    "resource_type": {
      "type": "string",
      "dynamic_enum": "resource_resource_type"
    },
    "tree": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:resource_tree) uri",
          "ifmissing": "error"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "restrictions": {
      "type": "boolean",
      "default": false
    },
    "repository_processing_note": {
      "type": "string",
      "maxLength": 65000
    },
    "ead_id": {
      "type": "string",
      "maxLength": 255
    },
    "ead_location": {
      "type": "string",
      "maxLength": 255
    },
    "finding_aid_title": {
      "type": "string",
      "maxLength": 65000
    },
    "finding_aid_subtitle": {
      "type": "string",
      "maxLength": 65000
    },
    "finding_aid_filing_title": {
      "type": "string",
      "maxLength": 65000
    },
    "finding_aid_date": {
      "type": "string",
      "maxLength": 255
    },
    "finding_aid_author": {
      "type": "string",
      "maxLength": 65000
    },
    "finding_aid_description_rules": {
      "type": "string",
      "dynamic_enum": "resource_finding_aid_description_rules"
    },
    "finding_aid_language": {
      "type": "string",
      "maxLength": 255
    },
    "finding_aid_sponsor": {
      "type": "string",
      "maxLength": 65000
    },
    "finding_aid_edition_statement": {
      "type": "string",
      "maxLength": 65000
    },
    "finding_aid_series_statement": {
      "type": "string",
      "maxLength": 65000
    },
    "finding_aid_status": {
      "type": "string",
      "dynamic_enum": "resource_finding_aid_status"
    },
    "finding_aid_note": {
      "type": "string",
      "maxLength": 65000
    },
    "revision_statements": {
      "type": "array",
      "items": {
        "type": "JSONModel(:revision_statement) object"
      }
    },
    "instances": {
      "type": "array",
      "items": {
        "type": "JSONModel(:instance) object"
      }
    },
    "deaccessions": {
      "type": "array",
      "items": {
        "type": "JSONModel(:deaccession) object"
      }
    },
    "collection_management": {
      "type": "JSONModel(:collection_management) object"
    },
    "user_defined": {
      "type": "JSONModel(:user_defined) object"
    },
    "related_accessions": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              {
                "type": "JSONModel(:accession) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "classifications": {
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              {
                "type": "JSONModel(:classification) uri"
              },
              {
                "type": "JSONModel(:classification_term) uri"
              }
            ],
            "ifmissing": "error"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "notes": {
      "type": "array",
      "items": {
        "type": [
          {
            "type": "JSONModel(:note_bibliography) object"
          },
          {
            "type": "JSONModel(:note_index) object"
          },
          {
            "type": "JSONModel(:note_multipart) object"
          },
          {
            "type": "JSONModel(:note_singlepart) object"
          }
        ]
      }
    },
    "representative_image": {
      "type": "JSONModel(:file_version) object",
      "readonly": true
    }
  },
  "validations": [
    [
      "error",
      "resource_check_identifier"
    ],
    [
      "warning",
      "check_resource_otherlevel"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | items | minLength | maxLength | ifmissing | dynamic_enum | readonly | minItems | subtype | default  
 ----- | ---- | -------- | ----- | --------- | --------- | --------- | ------------ | -------- | -------- | ------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  |  |  
 external_ids | array |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  |  |  |  
 title | string |  |  | 1 | 16384 | error |  |  |  |  |  
 language | string |  |  |  |  | warn | language_iso639_2 |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  |  |  
 subjects | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:subject) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  |  
 linked_events | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:event) uri", "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  | true |  |  |  
 extents | array |  | {"type"=>"JSONModel(:extent) object"} |  |  | error |  |  | 1 |  |  
 dates | array |  | {"type"=>"JSONModel(:date) object"} |  |  | error |  |  | 1 |  |  
 external_documents | array |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  |  |  |  |  |  
 rights_statements | array |  | {"type"=>"JSONModel(:rights_statement) object"} |  |  |  |  |  |  |  |  
 linked_agents | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"role"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_role", "ifmissing"=>"error"}, "terms"=>{"type"=>"array", "items"=>{"type"=>"JSONModel(:term) uri_or_object"}}, "relator"=>{"type"=>"string", "dynamic_enum"=>"linked_agent_archival_record_relators"}, "title"=>{"type"=>"string"}, "ref"=>{"type"=>[{"type"=>"JSONModel(:agent_corporate_entity) uri"}, {"type"=>"JSONModel(:agent_family) uri"}, {"type"=>"JSONModel(:agent_person) uri"}, {"type"=>"JSONModel(:agent_software) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  |  
 suppressed | boolean |  |  |  |  |  |  | true |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error |  |  |  |  |  
 created_by | string |  |  |  |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  |  |  |  | true |  |  |  
 create_time | date-time |  |  |  |  |  |  | true |  |  |  
 repository | object |  |  |  |  |  |  | true |  | ref |  
 id_0 | string |  |  |  | 255 | error |  |  |  |  |  
 id_1 | string |  |  |  | 255 |  |  |  |  |  |  
 id_2 | string |  |  |  | 255 |  |  |  |  |  |  
 id_3 | string |  |  |  | 255 |  |  |  |  |  |  
 level | string |  |  |  |  | error | archival_record_level |  |  |  |  
 other_level | string |  |  |  | 255 |  |  |  |  |  |  
 resource_type | string |  |  |  |  |  | resource_resource_type |  |  |  |  
 tree | object |  |  |  |  |  |  |  |  | ref |  
 restrictions | boolean |  |  |  |  |  |  |  |  |  |  
 repository_processing_note | string |  |  |  | 65000 |  |  |  |  |  |  
 ead_id | string |  |  |  | 255 |  |  |  |  |  |  
 ead_location | string |  |  |  | 255 |  |  |  |  |  |  
 finding_aid_title | string |  |  |  | 65000 |  |  |  |  |  |  
 finding_aid_subtitle | string |  |  |  | 65000 |  |  |  |  |  |  
 finding_aid_filing_title | string |  |  |  | 65000 |  |  |  |  |  |  
 finding_aid_date | string |  |  |  | 255 |  |  |  |  |  |  
 finding_aid_author | string |  |  |  | 65000 |  |  |  |  |  |  
 finding_aid_description_rules | string |  |  |  |  |  | resource_finding_aid_description_rules |  |  |  |  
 finding_aid_language | string |  |  |  | 255 |  |  |  |  |  |  
 finding_aid_sponsor | string |  |  |  | 65000 |  |  |  |  |  |  
 finding_aid_edition_statement | string |  |  |  | 65000 |  |  |  |  |  |  
 finding_aid_series_statement | string |  |  |  | 65000 |  |  |  |  |  |  
 finding_aid_status | string |  |  |  |  |  | resource_finding_aid_status |  |  |  |  
 finding_aid_note | string |  |  |  | 65000 |  |  |  |  |  |  
 revision_statements | array |  | {"type"=>"JSONModel(:revision_statement) object"} |  |  |  |  |  |  |  |  
 instances | array |  | {"type"=>"JSONModel(:instance) object"} |  |  |  |  |  |  |  |  
 deaccessions | array |  | {"type"=>"JSONModel(:deaccession) object"} |  |  |  |  |  |  |  |  
 collection_management | JSONModel(:collection_management) object |  |  |  |  |  |  |  |  |  |  
 user_defined | JSONModel(:user_defined) object |  |  |  |  |  |  |  |  |  |  
 related_accessions | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>[{"type"=>"JSONModel(:accession) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  |  
 classifications | array |  | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>[{"type"=>"JSONModel(:classification) uri"}, {"type"=>"JSONModel(:classification_term) uri"}], "ifmissing"=>"error"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  |  |  |  |  |  |  |  
 notes | array |  | {"type"=>[{"type"=>"JSONModel(:note_bibliography) object"}, {"type"=>"JSONModel(:note_index) object"}, {"type"=>"JSONModel(:note_multipart) object"}, {"type"=>"JSONModel(:note_singlepart) object"}]} |  |  |  |  |  |  |  |  
 representative_image | JSONModel(:file_version) object |  |  |  |  |  |  | true |  |  |  




##JSONModel(:resource_tree)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/resources/:resource_id/tree",
  "parent": "record_tree",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "id": {
      "type": "integer",
      "ifmissing": "error"
    },
    "record_uri": {
      "type": "string",
      "ifmissing": "error"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "required": false,
      "maxLength": 16384
    },
    "suppressed": {
      "type": "boolean",
      "default": false
    },
    "publish": {
      "type": "boolean"
    },
    "has_children": {
      "type": "boolean",
      "readonly": true
    },
    "node_type": {
      "type": "string",
      "maxLength": 255
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "finding_aid_filing_title": {
      "type": "string",
      "maxLength": 65000
    },
    "level": {
      "type": "string",
      "maxLength": 255
    },
    "component_id": {
      "type": "string",
      "maxLength": 255
    },
    "instance_types": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "containers": {
      "type": "array",
      "items": {
        "type": "object"
      }
    },
    "children": {
      "type": "array",
      "additionalItems": false,
      "items": {
        "type": "JSONModel(:resource_tree) object"
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | ifmissing | minLength | maxLength | default | readonly | subtype | items | additionalItems  
 ----- | ---- | -------- | --------- | --------- | --------- | ------- | -------- | ------- | ----- | --------------- |  
 uri | string |  |  |  |  |  |  |  |  |  
 id | integer |  | error |  |  |  |  |  |  |  
 record_uri | string |  | error |  |  |  |  |  |  |  
 title | string |  |  | 1 | 16384 |  |  |  |  |  
 suppressed | boolean |  |  |  |  |  |  |  |  |  
 publish | boolean |  |  |  |  |  |  |  |  |  
 has_children | boolean |  |  |  |  |  | true |  |  |  
 node_type | string |  |  |  | 255 |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  |  |  
 created_by | string |  |  |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  |  |  | true |  |  |  
 create_time | date-time |  |  |  |  |  | true |  |  |  
 repository | object |  |  |  |  |  | true | ref |  |  
 finding_aid_filing_title | string |  |  |  | 65000 |  |  |  |  |  
 level | string |  |  |  | 255 |  |  |  |  |  
 component_id | string |  |  |  | 255 |  |  |  |  |  
 instance_types | array |  |  |  |  |  |  |  | {"type"=>"string"} |  
 containers | array |  |  |  |  |  |  |  | {"type"=>"object"} |  
 children | array |  |  |  |  |  |  |  | {"type"=>"JSONModel(:resource_tree) object"} |  




##JSONModel(:revision_statement)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/revision_statement",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "date": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error"
    },
    "description": {
      "type": "string",
      "maxLength": 65000,
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | readonly | subtype  
 ----- | ---- | -------- | --------- | --------- | -------- | ------- |  
 uri | string |  |  |  |  |  
 date | string |  | 255 | error |  |  
 description | string |  | 65000 | error |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  
 created_by | string |  |  |  | true |  
 last_modified_by | string |  |  |  | true |  
 user_mtime | date-time |  |  |  | true |  
 system_mtime | date-time |  |  |  | true |  
 create_time | date-time |  |  |  | true |  
 repository | object |  |  |  | true | ref 




##JSONModel(:rights_restriction)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "begin": {
      "type": "string"
    },
    "end": {
      "type": "string"
    },
    "local_access_restriction_type": {
      "type": "array",
      "items": {
        "type": "string",
        "dynamic_enum": "restriction_type"
      }
    },
    "linked_records": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": [
            {
              "type": "JSONModel(:archival_object) uri"
            },
            {
              "type": "JSONModel(:resource) uri"
            }
          ]
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "restriction_note_type": {
      "type": "string",
      "readonly": "true"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | items | subtype | readonly | required | ifmissing  
 ----- | ---- | ----- | ------- | -------- | -------- | --------- |  
 begin | string |  |  |  |  |  
 end | string |  |  |  |  |  
 local_access_restriction_type | array | {"type"=>"string", "dynamic_enum"=>"restriction_type"} |  |  |  |  
 linked_records | object |  | ref |  |  |  
 restriction_note_type | string |  |  | true |  |  
 lock_version | integer | string |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  | error 
 created_by | string |  |  | true |  |  
 last_modified_by | string |  |  | true |  |  
 user_mtime | date-time |  |  | true |  |  
 system_mtime | date-time |  |  | true |  |  
 create_time | date-time |  |  | true |  |  
 repository | object |  | ref | true |  |  




##JSONModel(:rights_statement)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "rights_type": {
      "type": "string",
      "minLength": 1,
      "ifmissing": "error",
      "dynamic_enum": "rights_statement_rights_type"
    },
    "identifier": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "required": false
    },
    "active": {
      "type": "boolean",
      "default": true
    },
    "materials": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "ip_status": {
      "type": "string",
      "required": false,
      "dynamic_enum": "rights_statement_ip_status"
    },
    "ip_expiration_date": {
      "type": "date",
      "required": false
    },
    "license_identifier_terms": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "statute_citation": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "jurisdiction": {
      "type": "string",
      "required": false,
      "dynamic_enum": "country_iso_3166"
    },
    "type_note": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "permissions": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "restrictions": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "restriction_start_date": {
      "type": "date",
      "required": false
    },
    "restriction_end_date": {
      "type": "date",
      "required": false
    },
    "granted_note": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_rights_statement"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | minLength | ifmissing | dynamic_enum | maxLength | required | default | items | readonly | subtype  
 ----- | ---- | --------- | --------- | ------------ | --------- | -------- | ------- | ----- | -------- | ------- |  
 rights_type | string | 1 | error | rights_statement_rights_type |  |  |  |  |  |  
 identifier | string | 1 |  |  | 255 |  |  |  |  |  
 active | boolean |  |  |  |  |  | true |  |  |  
 materials | string |  |  |  | 255 |  |  |  |  |  
 ip_status | string |  |  | rights_statement_ip_status |  |  |  |  |  |  
 ip_expiration_date | date |  |  |  |  |  |  |  |  |  
 license_identifier_terms | string |  |  |  | 255 |  |  |  |  |  
 statute_citation | string |  |  |  | 255 |  |  |  |  |  
 jurisdiction | string |  |  | country_iso_3166 |  |  |  |  |  |  
 type_note | string |  |  |  | 255 |  |  |  |  |  
 permissions | string |  |  |  | 65000 |  |  |  |  |  
 restrictions | string |  |  |  | 65000 |  |  |  |  |  
 restriction_start_date | date |  |  |  |  |  |  |  |  |  
 restriction_end_date | date |  |  |  |  |  |  |  |  |  
 granted_note | string |  |  |  | 255 |  |  |  |  |  
 external_documents | array |  |  |  |  |  |  | {"type"=>"JSONModel(:external_document) object"} |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  |  |  |  
 created_by | string |  |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  |  | true | ref 




##JSONModel(:sub_container)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "top_container": {
      "type": "object",
      "subtype": "ref",
      "ifmissing": "error",
      "properties": {
        "ref": {
          "type": "JSONModel(:top_container) uri",
          "ifmissing": "error"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "type_2": {
      "type": "string",
      "dynamic_enum": "container_type"
    },
    "indicator_2": {
      "type": "string",
      "maxLength": 255
    },
    "type_3": {
      "type": "string",
      "dynamic_enum": "container_type"
    },
    "indicator_3": {
      "type": "string",
      "maxLength": 255
    },
    "display_string": {
      "type": "string",
      "readonly": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_sub_container"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | subtype | ifmissing | dynamic_enum | maxLength | readonly | required  
 ----- | ---- | ------- | --------- | ------------ | --------- | -------- | -------- |  
 top_container | object | ref | error |  |  |  |  
 type_2 | string |  |  | container_type |  |  |  
 indicator_2 | string |  |  |  | 255 |  |  
 type_3 | string |  |  | container_type |  |  |  
 indicator_3 | string |  |  |  | 255 |  |  
 display_string | string |  |  |  |  | true |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  | error |  |  |  |  
 created_by | string |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  | true |  
 create_time | date-time |  |  |  |  | true |  
 repository | object | ref |  |  |  | true |  




##JSONModel(:subject)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/subjects",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "title": {
      "type": "string",
      "readonly": true
    },
    "external_ids": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_id) object"
      }
    },
    "is_linked_to_published_record": {
      "type": "boolean",
      "readonly": true
    },
    "publish": {
      "type": "boolean",
      "default": true,
      "readonly": true
    },
    "source": {
      "type": "string",
      "dynamic_enum": "subject_source",
      "ifmissing": "error"
    },
    "scope_note": {
      "type": "string"
    },
    "terms": {
      "type": "array",
      "items": {
        "type": "JSONModel(:term) uri_or_object"
      },
      "ifmissing": "error",
      "minItems": 1
    },
    "vocabulary": {
      "type": "JSONModel(:vocabulary) uri",
      "ifmissing": "error"
    },
    "authority_id": {
      "type": "string",
      "maxLength": 255
    },
    "external_documents": {
      "type": "array",
      "items": {
        "type": "JSONModel(:external_document) object"
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | readonly | items | default | dynamic_enum | ifmissing | minItems | maxLength | subtype  
 ----- | ---- | -------- | -------- | ----- | ------- | ------------ | --------- | -------- | --------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  |  
 title | string |  | true |  |  |  |  |  |  |  
 external_ids | array |  |  | {"type"=>"JSONModel(:external_id) object"} |  |  |  |  |  |  
 is_linked_to_published_record | boolean |  | true |  |  |  |  |  |  |  
 publish | boolean |  | true |  | true |  |  |  |  |  
 source | string |  |  |  |  | subject_source | error |  |  |  
 scope_note | string |  |  |  |  |  |  |  |  |  
 terms | array |  |  | {"type"=>"JSONModel(:term) uri_or_object"} |  |  | error | 1 |  |  
 vocabulary | JSONModel(:vocabulary) uri |  |  |  |  |  | error |  |  |  
 authority_id | string |  |  |  |  |  |  |  | 255 |  
 external_documents | array |  |  | {"type"=>"JSONModel(:external_document) object"} |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  |  
 created_by | string |  | true |  |  |  |  |  |  |  
 last_modified_by | string |  | true |  |  |  |  |  |  |  
 user_mtime | date-time |  | true |  |  |  |  |  |  |  
 system_mtime | date-time |  | true |  |  |  |  |  |  |  
 create_time | date-time |  | true |  |  |  |  |  |  |  
 repository | object |  | true |  |  |  |  |  |  | ref 




##JSONModel(:telephone)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/telephone",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "number": {
      "type": "string",
      "maxLength": 65000
    },
    "ext": {
      "type": "string",
      "maxLength": 65000
    },
    "number_type": {
      "type": "string",
      "required": false,
      "dynamic_enum": "telephone_number_type"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | dynamic_enum | ifmissing | readonly | subtype  
 ----- | ---- | -------- | --------- | ------------ | --------- | -------- | ------- |  
 uri | string |  |  |  |  |  |  
 number | string |  | 65000 |  |  |  |  
 ext | string |  | 65000 |  |  |  |  
 number_type | string |  |  | telephone_number_type |  |  |  
 lock_version | integer | string |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  | error |  |  
 created_by | string |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  | true |  
 create_time | date-time |  |  |  |  | true |  
 repository | object |  |  |  |  | true | ref 




##JSONModel(:term)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/terms",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "term": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "ifmissing": "error"
    },
    "term_type": {
      "type": "string",
      "minLength": 1,
      "ifmissing": "error",
      "dynamic_enum": "subject_term_type"
    },
    "vocabulary": {
      "type": "JSONModel(:vocabulary) uri",
      "ifmissing": "error"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | minLength | ifmissing | dynamic_enum | readonly | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ------------ | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  
 term | string |  | 255 | 1 | error |  |  |  
 term_type | string |  |  | 1 | error | subject_term_type |  |  
 vocabulary | JSONModel(:vocabulary) uri |  |  |  | error |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  | error |  |  |  
 created_by | string |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  | true | ref 




##JSONModel(:top_container)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/repositories/:repo_id/top_containers",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "indicator": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "ifmissing": "error"
    },
    "type": {
      "type": "string",
      "dynamic_enum": "container_type",
      "required": false
    },
    "barcode": {
      "type": "string",
      "maxLength": 255
    },
    "display_string": {
      "type": "string",
      "readonly": true
    },
    "long_display_string": {
      "type": "string",
      "readonly": true
    },
    "ils_holding_id": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "ils_item_id": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "exported_to_ils": {
      "type": "string",
      "required": false
    },
    "restricted": {
      "type": "boolean",
      "readonly": "true"
    },
    "active_restrictions": {
      "type": "array",
      "readonly": "true",
      "items": {
        "type": "JSONModel(:rights_restriction) object"
      }
    },
    "container_locations": {
      "type": "array",
      "items": {
        "type": "JSONModel(:container_location) object"
      }
    },
    "container_profile": {
      "type": "object",
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": "JSONModel(:container_profile) uri"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "series": {
      "readonly": "true",
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": "JSONModel(:archival_object) uri"
          },
          "display_string": {
            "type": "string"
          },
          "identifier": {
            "type": "string"
          },
          "level_display_string": {
            "type": "string"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "collection": {
      "readonly": "true",
      "type": "array",
      "items": {
        "type": "object",
        "subtype": "ref",
        "properties": {
          "ref": {
            "type": [
              {
                "type": "JSONModel(:resource) uri"
              },
              {
                "type": "JSONModel(:accession) uri"
              }
            ]
          },
          "display_string": {
            "type": "string"
          },
          "identifier": {
            "type": "string"
          },
          "_resolved": {
            "type": "object",
            "readonly": "true"
          }
        }
      }
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | minLength | ifmissing | dynamic_enum | readonly | items | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ------------ | -------- | ----- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 indicator | string |  | 255 | 1 | error |  |  |  |  
 type | string |  |  |  |  | container_type |  |  |  
 barcode | string |  | 255 |  |  |  |  |  |  
 display_string | string |  |  |  |  |  | true |  |  
 long_display_string | string |  |  |  |  |  | true |  |  
 ils_holding_id | string |  | 255 |  |  |  |  |  |  
 ils_item_id | string |  | 255 |  |  |  |  |  |  
 exported_to_ils | string |  |  |  |  |  |  |  |  
 restricted | boolean |  |  |  |  |  | true |  |  
 active_restrictions | array |  |  |  |  |  | true | {"type"=>"JSONModel(:rights_restriction) object"} |  
 container_locations | array |  |  |  |  |  |  | {"type"=>"JSONModel(:container_location) object"} |  
 container_profile | object |  |  |  |  |  |  |  | ref 
 series | array |  |  |  |  |  | true | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>"JSONModel(:archival_object) uri"}, "display_string"=>{"type"=>"string"}, "identifier"=>{"type"=>"string"}, "level_display_string"=>{"type"=>"string"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  
 collection | array |  |  |  |  |  | true | {"type"=>"object", "subtype"=>"ref", "properties"=>{"ref"=>{"type"=>[{"type"=>"JSONModel(:resource) uri"}, {"type"=>"JSONModel(:accession) uri"}]}, "display_string"=>{"type"=>"string"}, "identifier"=>{"type"=>"string"}, "_resolved"=>{"type"=>"object", "readonly"=>"true"}}} |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  | error |  |  |  |  
 created_by | string |  |  |  |  |  | true |  |  
 last_modified_by | string |  |  |  |  |  | true |  |  
 user_mtime | date-time |  |  |  |  |  | true |  |  
 system_mtime | date-time |  |  |  |  |  | true |  |  
 create_time | date-time |  |  |  |  |  | true |  |  
 repository | object |  |  |  |  |  | true |  | ref 




##JSONModel(:user)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/users",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "username": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error",
      "minLength": 1
    },
    "name": {
      "type": "string",
      "maxLength": 255,
      "ifmissing": "error",
      "minLength": 1
    },
    "is_system_user": {
      "type": "boolean",
      "readonly": true
    },
    "permissions": {
      "type": "object",
      "readonly": true
    },
    "groups": {
      "type": "array",
      "items": {
        "type": "JSONModel(:group) uri"
      }
    },
    "email": {
      "type": "string",
      "maxLength": 255
    },
    "first_name": {
      "type": "string",
      "maxLength": 255
    },
    "last_name": {
      "type": "string",
      "maxLength": 255
    },
    "telephone": {
      "type": "string",
      "maxLength": 255
    },
    "title": {
      "type": "string",
      "maxLength": 255
    },
    "department": {
      "type": "string",
      "maxLength": 255
    },
    "additional_contact": {
      "type": "string",
      "maxLength": 65000
    },
    "agent_record": {
      "type": "object",
      "readonly": true,
      "subtype": "ref",
      "properties": {
        "ref": {
          "type": [
            {
              "type": "JSONModel(:agent_person) uri"
            },
            {
              "type": "JSONModel(:agent_software) uri"
            }
          ]
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    },
    "is_admin": {
      "type": "boolean",
      "default": false
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | ifmissing | minLength | readonly | items | subtype | default  
 ----- | ---- | -------- | --------- | --------- | --------- | -------- | ----- | ------- | ------- |  
 uri | string |  |  |  |  |  |  |  |  
 username | string |  | 255 | error | 1 |  |  |  |  
 name | string |  | 255 | error | 1 |  |  |  |  
 is_system_user | boolean |  |  |  |  | true |  |  |  
 permissions | object |  |  |  |  | true |  |  |  
 groups | array |  |  |  |  |  | {"type"=>"JSONModel(:group) uri"} |  |  
 email | string |  | 255 |  |  |  |  |  |  
 first_name | string |  | 255 |  |  |  |  |  |  
 last_name | string |  | 255 |  |  |  |  |  |  
 telephone | string |  | 255 |  |  |  |  |  |  
 title | string |  | 255 |  |  |  |  |  |  
 department | string |  | 255 |  |  |  |  |  |  
 additional_contact | string |  | 65000 |  |  |  |  |  |  
 agent_record | object |  |  |  |  | true |  | ref |  
 is_admin | boolean |  |  |  |  |  |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  | error |  |  |  |  |  
 created_by | string |  |  |  |  | true |  |  |  
 last_modified_by | string |  |  |  |  | true |  |  |  
 user_mtime | date-time |  |  |  |  | true |  |  |  
 system_mtime | date-time |  |  |  |  | true |  |  |  
 create_time | date-time |  |  |  |  | true |  |  |  
 repository | object |  |  |  |  | true |  | ref |  




##JSONModel(:user_defined)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "properties": {
    "boolean_1": {
      "type": "boolean",
      "default": false
    },
    "boolean_2": {
      "type": "boolean",
      "default": false
    },
    "boolean_3": {
      "type": "boolean",
      "default": false
    },
    "integer_1": {
      "type": "string",
      "maxlength": 255,
      "required": false
    },
    "integer_2": {
      "type": "string",
      "maxlength": 255,
      "required": false
    },
    "integer_3": {
      "type": "string",
      "maxlength": 255,
      "required": false
    },
    "real_1": {
      "type": "string",
      "maxlength": 13,
      "required": false
    },
    "real_2": {
      "type": "string",
      "maxlength": 13,
      "required": false
    },
    "real_3": {
      "type": "string",
      "maxlength": 13,
      "required": false
    },
    "string_1": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "string_2": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "string_3": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "string_4": {
      "type": "string",
      "maxLength": 255,
      "required": false
    },
    "text_1": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "text_2": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "text_3": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "text_4": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "text_5": {
      "type": "string",
      "maxLength": 65000,
      "required": false
    },
    "date_1": {
      "type": "date",
      "required": false
    },
    "date_2": {
      "type": "date",
      "required": false
    },
    "date_3": {
      "type": "date",
      "required": false
    },
    "enum_1": {
      "type": "string",
      "dynamic_enum": "user_defined_enum_1"
    },
    "enum_2": {
      "type": "string",
      "dynamic_enum": "user_defined_enum_2"
    },
    "enum_3": {
      "type": "string",
      "dynamic_enum": "user_defined_enum_3"
    },
    "enum_4": {
      "type": "string",
      "dynamic_enum": "user_defined_enum_4"
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  },
  "validations": [
    [
      "error",
      "check_user-defined"
    ]
  ]
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | default | maxlength | required | maxLength | dynamic_enum | ifmissing | readonly | subtype  
 ----- | ---- | ------- | --------- | -------- | --------- | ------------ | --------- | -------- | ------- |  
 boolean_1 | boolean |  |  |  |  |  |  |  |  
 boolean_2 | boolean |  |  |  |  |  |  |  |  
 boolean_3 | boolean |  |  |  |  |  |  |  |  
 integer_1 | string |  | 255 |  |  |  |  |  |  
 integer_2 | string |  | 255 |  |  |  |  |  |  
 integer_3 | string |  | 255 |  |  |  |  |  |  
 real_1 | string |  | 13 |  |  |  |  |  |  
 real_2 | string |  | 13 |  |  |  |  |  |  
 real_3 | string |  | 13 |  |  |  |  |  |  
 string_1 | string |  |  |  | 255 |  |  |  |  
 string_2 | string |  |  |  | 255 |  |  |  |  
 string_3 | string |  |  |  | 255 |  |  |  |  
 string_4 | string |  |  |  | 255 |  |  |  |  
 text_1 | string |  |  |  | 65000 |  |  |  |  
 text_2 | string |  |  |  | 65000 |  |  |  |  
 text_3 | string |  |  |  | 65000 |  |  |  |  
 text_4 | string |  |  |  | 65000 |  |  |  |  
 text_5 | string |  |  |  | 65000 |  |  |  |  
 date_1 | date |  |  |  |  |  |  |  |  
 date_2 | date |  |  |  |  |  |  |  |  
 date_3 | date |  |  |  |  |  |  |  |  
 enum_1 | string |  |  |  |  | user_defined_enum_1 |  |  |  
 enum_2 | string |  |  |  |  | user_defined_enum_2 |  |  |  
 enum_3 | string |  |  |  |  | user_defined_enum_3 |  |  |  
 enum_4 | string |  |  |  |  | user_defined_enum_4 |  |  |  
 lock_version | integer | string |  |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  |  |  | error |  |  
 created_by | string |  |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  |  | true | ref 




##JSONModel(:vocabulary)
```json

{
  "$schema": "http://www.archivesspace.org/archivesspace.json",
  "version": 1,
  "type": "object",
  "uri": "/vocabularies",
  "properties": {
    "uri": {
      "type": "string",
      "required": false
    },
    "ref_id": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "ifmissing": "error"
    },
    "name": {
      "type": "string",
      "maxLength": 255,
      "minLength": 1,
      "ifmissing": "error"
    },
    "terms": {
      "type": "array",
      "items": {
        "type": "JSONModel(:term) uri"
      },
      "readonly": true
    },
    "lock_version": {
      "type": [
        "integer",
        "string"
      ],
      "required": false
    },
    "jsonmodel_type": {
      "type": "string",
      "ifmissing": "error"
    },
    "created_by": {
      "type": "string",
      "readonly": true
    },
    "last_modified_by": {
      "type": "string",
      "readonly": true
    },
    "user_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "system_mtime": {
      "type": "date-time",
      "readonly": true
    },
    "create_time": {
      "type": "date-time",
      "readonly": true
    },
    "repository": {
      "type": "object",
      "subtype": "ref",
      "readonly": "true",
      "properties": {
        "ref": {
          "type": "JSONModel(:repository) uri",
          "ifmissing": "error",
          "readonly": "true"
        },
        "_resolved": {
          "type": "object",
          "readonly": "true"
        }
      }
    }
  }
}
```
 
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  
  
   
  

 title | type | required | maxLength | minLength | ifmissing | items | readonly | subtype  
 ----- | ---- | -------- | --------- | --------- | --------- | ----- | -------- | ------- |  
 uri | string |  |  |  |  |  |  |  
 ref_id | string |  | 255 | 1 | error |  |  |  
 name | string |  | 255 | 1 | error |  |  |  
 terms | array |  |  |  |  | {"type"=>"JSONModel(:term) uri"} | true |  
 lock_version | integer | string |  |  |  |  |  |  |  
 jsonmodel_type | string |  |  |  | error |  |  |  
 created_by | string |  |  |  |  |  | true |  
 last_modified_by | string |  |  |  |  |  | true |  
 user_mtime | date-time |  |  |  |  |  | true |  
 system_mtime | date-time |  |  |  |  |  | true |  
 create_time | date-time |  |  |  |  |  | true |  
 repository | object |  |  |  |  |  | true | ref 



