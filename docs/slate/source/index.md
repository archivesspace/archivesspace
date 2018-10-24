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
As of 2018-10-16 08:39:01 -0700 the following REST endpoints exist in the master branch of the development repository:


## [:POST] /agents/corporate_entities 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number_type":"home",
"number":"6564 1053 552"}],
"name":"Name Number 599",
"address_1":"RDKBN",
"address_3":"HIDWR",
"city":"1898837S545",
"country":"JWPWR",
"email":"U818930HS",
"email_signature":"656612W950C",
"note":"813671555C268"}],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"existence",
"begin":"1982-04-24",
"end":"1982-04-24",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"VXP512G"}],
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"primary_name":"Name Number 598",
"subordinate_name_1":"F76TBF",
"subordinate_name_2":"RDEKA",
"number":"SY577356405",
"sort_name":"SORT g - 516",
"dates":"S64X620R",
"qualifier":"472IQH800",
"authority_id":"http://www.example-563.com",
"source":"naf"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089/agents/corporate_entities"

```

__Description__

Create a corporate entity agent

__Parameters__


	JSONModel(:agent_corporate_entity) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /agents/corporate_entities 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/corporate_entities?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/corporate_entities?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/corporate_entities?all_ids=true"
  

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



## [:POST] /agents/corporate_entities/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number_type":"home",
"number":"6564 1053 552"}],
"name":"Name Number 599",
"address_1":"RDKBN",
"address_3":"HIDWR",
"city":"1898837S545",
"country":"JWPWR",
"email":"U818930HS",
"email_signature":"656612W950C",
"note":"813671555C268"}],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"existence",
"begin":"1982-04-24",
"end":"1982-04-24",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"VXP512G"}],
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"primary_name":"Name Number 598",
"subordinate_name_1":"F76TBF",
"subordinate_name_2":"RDEKA",
"number":"SY577356405",
"sort_name":"SORT g - 516",
"dates":"S64X620R",
"qualifier":"472IQH800",
"authority_id":"http://www.example-563.com",
"source":"naf"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089/agents/corporate_entities/1"

```

__Description__

Update a corporate entity agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_corporate_entity) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /agents/corporate_entities/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/corporate_entities/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a corporate entity by ID

__Parameters__


	Integer id -- ID of the corporate entity agent

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent_corporate_entity)
	404 -- Not found



## [:DELETE] /agents/corporate_entities/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/agents/corporate_entities/1"

```

__Description__

Delete a corporate entity agent

__Parameters__


	Integer id -- ID of the corporate entity agent

__Returns__

	200 -- deleted



## [:POST] /agents/families 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_family",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"2017-08-02",
"end":"2017-08-02",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"H51UL436"}],
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"local",
"family_name":"Name Number 600",
"sort_name":"SORT b - 517",
"dates":"FVDJK",
"qualifier":"G984563E512",
"prefix":"L410SAH",
"authority_id":"http://www.example-564.com",
"source":"local"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089/agents/families"

```

__Description__

Create a family agent

__Parameters__


	JSONModel(:agent_family) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /agents/families 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/families?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/families?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/families?all_ids=true"
  

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



## [:POST] /agents/families/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_family",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"2017-08-02",
"end":"2017-08-02",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"H51UL436"}],
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"local",
"family_name":"Name Number 600",
"sort_name":"SORT b - 517",
"dates":"FVDJK",
"qualifier":"G984563E512",
"prefix":"L410SAH",
"authority_id":"http://www.example-564.com",
"source":"local"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089/agents/families/1"

```

__Description__

Update a family agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_family) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /agents/families/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/families/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a family by ID

__Parameters__


	Integer id -- ID of the family agent

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found



## [:DELETE] /agents/families/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/agents/families/1"

```

__Description__

Delete an agent family

__Parameters__


	Integer id -- ID of the family agent

__Returns__

	200 -- deleted



## [:POST] /agents/people 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_person",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"existence",
"begin":"2002-01-27",
"end":"2002-01-27",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"184LYXV"}],
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"source":"ulan",
"primary_name":"Name Number 601",
"sort_name":"SORT q - 518",
"name_order":"direct",
"number":"NQVTX",
"dates":"246TH448J",
"qualifier":"DPKBB",
"fuller_form":"Q606A77R",
"prefix":"PCQIV",
"suffix":"392NXL448",
"rest_of_name":"444G722QX",
"authority_id":"http://www.example-565.com"}],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089/agents/people"

```

__Description__

Create a person agent

__Parameters__


	JSONModel(:agent_person) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /agents/people 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/people?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/people?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/people?all_ids=true"
  

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



## [:POST] /agents/people/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_person",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"existence",
"begin":"2002-01-27",
"end":"2002-01-27",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"184LYXV"}],
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"source":"ulan",
"primary_name":"Name Number 601",
"sort_name":"SORT q - 518",
"name_order":"direct",
"number":"NQVTX",
"dates":"246TH448J",
"qualifier":"DPKBB",
"fuller_form":"Q606A77R",
"prefix":"PCQIV",
"suffix":"392NXL448",
"rest_of_name":"444G722QX",
"authority_id":"http://www.example-565.com"}],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089/agents/people/1"

```

__Description__

Update a person agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_person) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /agents/people/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/people/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a person by ID

__Parameters__


	Integer id -- ID of the person agent

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found



## [:DELETE] /agents/people/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/agents/people/1"

```

__Description__

Delete an agent person

__Parameters__


	Integer id -- ID of the person agent

__Returns__

	200 -- deleted



## [:POST] /agents/software 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_software",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"1970-01-10",
"end":"1970-01-10",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"NBFVK"}],
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"local",
"software_name":"Name Number 602",
"sort_name":"SORT w - 519"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089/agents/software"

```

__Description__

Create a software agent

__Parameters__


	JSONModel(:agent_software) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /agents/software 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/software?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/software?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/software?all_ids=true"
  

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



## [:POST] /agents/software/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_software",
"agent_contacts":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"1970-01-10",
"end":"1970-01-10",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"NBFVK"}],
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"local",
"software_name":"Name Number 602",
"sort_name":"SORT w - 519"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089/agents/software/1"

```

__Description__

Update a software agent

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:agent_software) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /agents/software/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/agents/software/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a software agent by ID

__Parameters__


	Integer id -- ID of the software agent

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:agent)
	404 -- Not found



## [:DELETE] /agents/software/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/agents/software/1"

```

__Description__

Delete a software agent

__Parameters__


	Integer id -- ID of the software agent

__Returns__

	200 -- deleted



## [:POST] /batch_delete 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/batch_delete?record_uris=417HODJ"

```

__Description__

Carry out delete requests against a list of records

__Parameters__


	[String] record_uris -- A list of record uris

__Returns__

	200 -- deleted



## [:GET] /by-external-id 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/by-external-id?eid=567TCGR&type=445W857JG"
  

```

__Description__

List records by their external ID(s)

__Parameters__


	String eid -- An external ID to find

	[String] type (Optional) -- The record type to search (useful if IDs may be shared between different types)

__Returns__

	303 -- A redirect to the URI named by the external ID (if there's only one)
	300 -- A JSON-formatted list of URIs if there were multiple matches
	404 -- No external ID matched



## [:GET] /config/enumeration_values/:enum_val_id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/config/enumeration_values/1"
  

```

__Description__

Get an Enumeration Value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to retrieve

__Returns__

	200 -- (:enumeration_value)



## [:POST] /config/enumeration_values/:enum_val_id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/config/enumeration_values/1"

```

__Description__

Update an enumeration value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	JSONModel(:enumeration_value) <request body> -- The enumeration value to update

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:POST] /config/enumeration_values/:enum_val_id/position 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/config/enumeration_values/1/position?position=1"

```

__Description__

Update the position of an ennumeration value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	Integer position -- The target position in the value list

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:POST] /config/enumeration_values/:enum_val_id/suppressed 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/config/enumeration_values/1/suppressed?suppressed=true"

```

__Description__

Suppress this value

__Parameters__


	Integer enum_val_id -- The ID of the enumeration value to update

	RESTHelpers::BooleanParam suppressed -- Suppression state

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}
	400 -- {:error => (description of error)}



## [:GET] /config/enumerations 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/config/enumerations"
  

```

__Description__

List all defined enumerations

__Parameters__


__Returns__

	200 -- [(:enumeration)]



## [:POST] /config/enumerations 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/config/enumerations"

```

__Description__

Create an enumeration

__Parameters__


	JSONModel(:enumeration) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:POST] /config/enumerations/:enum_id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/config/enumerations/1"

```

__Description__

Update an enumeration

__Parameters__


	Integer enum_id -- The ID of the enumeration to update

	JSONModel(:enumeration) <request body> -- The enumeration to update

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /config/enumerations/:enum_id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/config/enumerations/1"
  

```

__Description__

Get an Enumeration

__Parameters__


	Integer enum_id -- The ID of the enumeration to retrieve

__Returns__

	200 -- (:enumeration)



## [:POST] /config/enumerations/migration 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/config/enumerations/migration"

```

__Description__

Migrate all records from using one value to another

__Parameters__


	JSONModel(:enumeration_migration) <request body> -- The migration request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /config/enumerations/names/:enum_name 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/config/enumerations/names/1"
  

```

__Description__

Get an Enumeration by Name

__Parameters__


	String enum_name -- The name of the enumeration to retrieve

__Returns__

	200 -- (:enumeration)



## [:POST] /container_profiles 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"786T853I208",
"url":"RPLC817",
"dimension_units":"feet",
"extent_dimension":"width",
"depth":"79",
"height":"90",
"width":"17"}' \
  "http://localhost:8089/container_profiles"

```

__Description__

Create a Container_Profile

__Parameters__


	JSONModel(:container_profile) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## [:GET] /container_profiles 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/container_profiles?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/container_profiles?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/container_profiles?all_ids=true"
  

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



## [:POST] /container_profiles/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"786T853I208",
"url":"RPLC817",
"dimension_units":"feet",
"extent_dimension":"width",
"depth":"79",
"height":"90",
"width":"17"}' \
  "http://localhost:8089/container_profiles/1"

```

__Description__

Update a Container Profile

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:container_profile) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /container_profiles/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/container_profiles/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Container Profile by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:container_profile)



## [:DELETE] /container_profiles/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/container_profiles/1"

```

__Description__

Delete an Container Profile

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted



## [:GET] /current_global_preferences 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/current_global_preferences"
  

```

__Description__

Get the global Preferences records for the current user.

__Parameters__


__Returns__

	200 -- {(:preference)}



## [:GET] /date_calculator 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/date_calculator?record_uri=37JOTC&label=FLMV124"
  

```

__Description__

Calculate the dates of an archival object tree

__Parameters__


	String record_uri -- The uri of the object

	String label (Optional) -- The date label to filter on

__Returns__

	200 -- Calculation results



## [:GET] /delete-feed 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/delete-feed?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/delete-feed?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/delete-feed?all_ids=true"
  

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



## [:GET] /extent_calculator 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/extent_calculator?record_uri=334597D769831&unit=FP99187H"
  

```

__Description__

Calculate the extent of an archival object tree

__Parameters__


	String record_uri -- The uri of the object

	String unit (Optional) -- The unit of measurement to use

__Returns__

	200 -- Calculation results



## [:GET] /job_types 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/job_types"
  

```

__Description__

List all supported job types

__Parameters__


__Returns__

	200 -- A list of supported job types



## [:POST] /location_profiles 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"THE451139",
"dimension_units":"centimeters",
"depth":"63",
"height":"23",
"width":"59"}' \
  "http://localhost:8089/location_profiles"

```

__Description__

Create a Location_Profile

__Parameters__


	JSONModel(:location_profile) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## [:GET] /location_profiles 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/location_profiles?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/location_profiles?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/location_profiles?all_ids=true"
  

```

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



## [:POST] /location_profiles/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"THE451139",
"dimension_units":"centimeters",
"depth":"63",
"height":"23",
"width":"59"}' \
  "http://localhost:8089/location_profiles/1"

```

__Description__

Update a Location Profile

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:location_profile) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /location_profiles/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/location_profiles/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Location Profile by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:location_profile)



## [:DELETE] /location_profiles/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/location_profiles/1"

```

__Description__

Delete an Location Profile

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted



## [:POST] /locations 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location",
"external_ids":[],
"functions":[],
"building":"13 E 9th Street",
"floor":"7",
"room":"7",
"area":"Back",
"barcode":"01010110110010011111",
"temporary":"reading_room"}' \
  "http://localhost:8089/locations"

```

__Description__

Create a Location

__Parameters__


	JSONModel(:location) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## [:GET] /locations 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/locations?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/locations?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/locations?all_ids=true"
  

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



## [:POST] /locations/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location",
"external_ids":[],
"functions":[],
"building":"13 E 9th Street",
"floor":"7",
"room":"7",
"area":"Back",
"barcode":"01010110110010011111",
"temporary":"reading_room"}' \
  "http://localhost:8089/locations/1"

```

__Description__

Update a Location

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:location) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /locations/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/locations/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Location by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:location)



## [:DELETE] /locations/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/locations/1"

```

__Description__

Delete a Location

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted



## [:POST] /locations/batch 



  
  
    
      
        
      
    
  
  

  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/locations/batch?dry_run=true"

```

__Description__

Create a Batch of Locations

__Parameters__


	RESTHelpers::BooleanParam dry_run (Optional) -- If true, don't create the locations, just list them

	JSONModel(:location_batch) <request body> -- The location batch data to generate all locations

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /locations/batch_update 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/locations/batch_update"

```

__Description__

Update a Location

__Parameters__


	JSONModel(:location_batch_update) <request body> -- The location batch data to update all locations

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /logout 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/logout"

```

__Description__

Log out the current session

__Parameters__


__Returns__

	200 -- Session logged out



## [:POST] /merge_requests/agent 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/merge_requests/agent"

```

__Description__

Carry out a merge request against Agent records

__Parameters__


	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /merge_requests/digital_object 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/merge_requests/digital_object"

```

__Description__

Carry out a merge request against Digital_Object records

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /merge_requests/resource 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/merge_requests/resource"

```

__Description__

Carry out a merge request against Resource records

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /merge_requests/subject 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/merge_requests/subject"

```

__Description__

Carry out a merge request against Subject records

__Parameters__


	JSONModel(:merge_request) <request body> -- A merge request

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /notifications 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/notifications?last_sequence=1"
  

```

__Description__

Get a stream of notifications

__Parameters__


	Integer last_sequence (Optional) -- The last sequence number seen

__Returns__

	200 -- a list of notifications



## [:GET] /oai 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/oai?verb=GS259G869&metadataPrefix=VJG77842&from=698752R896I&until=249628SNX&resumptionToken=E386M802C&set=YKP422E&identifier=UAKNC"
  

```

__Description__

Handle an OAI request

__Parameters__


	String verb -- The OAI verb (Identify, ListRecords, GetRecord, etc.)

	String metadataPrefix (Optional) -- One of the supported metadata types.  See verb=ListMetadataFormats for a list.

	String from (Optional) -- Start date (yyyy-mm-dd, yyyy-mm-ddThh:mm:ssZ)

	String until (Optional) -- End date (yyyy-mm-dd, yyyy-mm-ddThh:mm:ssZ)

	String resumptionToken (Optional) -- The OAI resumption token

	String set (Optional) -- Requested OAI set (see ?verb=Identify for available sets)

	String identifier (Optional) -- The requested record identifier (for ?verb=GetRecord)

__Returns__

	200 -- OAI response



## [:GET] /oai_sample 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/oai_sample"
  

```

__Description__

A HTML form to generate one sample OAI requests

__Parameters__


__Returns__

	200 -- HTML



## [:GET] /permissions 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/permissions?level=397320D78P"
  

```

__Description__

Get a list of Permissions

__Parameters__


	String level -- The permission level to get (one of: repository, global, all) -- Must be one of repository, global, all

__Returns__

	200 -- [(:permission)]



## [:GET] /reports 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/reports"
  

```

__Description__

List all reports

__Parameters__


__Returns__

	200 -- report list in json



## [:GET] /reports/static/* 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/reports/static/*?splat=91667UR301"
  

```

__Description__

Get a static asset for a report

__Parameters__


	String splat -- The requested asset

__Returns__

	200 -- the asset



## [:POST] /repositories 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories"

```

__Description__

Create a Repository

__Parameters__


	JSONModel(:repository) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	403 -- access_denied



## [:GET] /repositories 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a list of Repositories

__Parameters__


	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- [(:repository)]



## [:POST] /repositories/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/1"

```

__Description__

Update a repository

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:repository) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /repositories/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Repository by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:repository)
	404 -- Not found



## [:DELETE] /repositories/:repo_id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2"

```

__Description__

Delete a Repository

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/accessions 




  
  

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
"id_0":"AE579HF",
"id_1":"S31BA608",
"id_2":"210M685HL",
"id_3":"TW338744494",
"title":"Accession Title: 367",
"content_description":"Description: 274",
"condition_description":"Description: 275",
"accession_date":"2010-02-27"}' \
  "http://localhost:8089/repositories/2/accessions"

```

__Description__

Create an Accession

__Parameters__


	JSONModel(:accession) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## [:GET] /repositories/:repo_id/accessions 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/accessions?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/accessions?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/accessions?all_ids=true"
  

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



## [:POST] /repositories/:repo_id/accessions/:id 




  
  

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
"id_0":"AE579HF",
"id_1":"S31BA608",
"id_2":"210M685HL",
"id_3":"TW338744494",
"title":"Accession Title: 367",
"content_description":"Description: 274",
"condition_description":"Description: 275",
"accession_date":"2010-02-27"}' \
  "http://localhost:8089/repositories/2/accessions/1"

```

__Description__

Update an Accession

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:accession) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /repositories/:repo_id/accessions/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/accessions/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get an Accession by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:accession)



## [:DELETE] /repositories/:repo_id/accessions/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/accessions/1"

```

__Description__

Delete an Accession

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/accessions/:id/suppressed 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/accessions/1/suppressed?suppressed=true"

```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## [:GET] /repositories/:repo_id/accessions/:id/top_containers 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/accessions/1/top_containers?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get Top Containers linked to an Accession

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- a list of linked top containers
	404 -- Not found



## [:POST] /repositories/:repo_id/accessions/:id/transfer 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/accessions/1/transfer?target_repo=X904417112D"

```

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved



## [:GET] /repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_contexts/corporate_entities/1.:fmt/metadata"
  

```

__Description__

Get metadata for an EAC-CPF export of a corporate entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/archival_contexts/corporate_entities/:id.xml 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_contexts/corporate_entities/1.xml"
  

```

__Description__

Get an EAC-CPF representation of a Corporate Entity

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)



## [:GET] /repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_contexts/families/1.:fmt/metadata"
  

```

__Description__

Get metadata for an EAC-CPF export of a family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/archival_contexts/families/:id.xml 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_contexts/families/1.xml"
  

```

__Description__

Get an EAC-CPF representation of a Family

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)



## [:GET] /repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_contexts/people/1.:fmt/metadata"
  

```

__Description__

Get metadata for an EAC-CPF export of a person

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/archival_contexts/people/:id.xml 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_contexts/people/1.xml"
  

```

__Description__

Get an EAC-CPF representation of an Agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)



## [:GET] /repositories/:repo_id/archival_contexts/softwares/:id.:fmt/metadata 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_contexts/softwares/1.:fmt/metadata"
  

```

__Description__

Get metadata for an EAC-CPF export of a software

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/archival_contexts/softwares/:id.xml 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_contexts/softwares/1.xml"
  

```

__Description__

Get an EAC-CPF representation of a Software agent

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:agent)



## [:POST] /repositories/:repo_id/archival_objects 




  
  

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
"ref_id":"T176NHY",
"level":"series",
"title":"Archival Object Title: 368",
"resource":{ "ref":"/repositories/2/resources/158"}}' \
  "http://localhost:8089/repositories/2/archival_objects"

```

__Description__

Create an Archival Object

__Parameters__


	JSONModel(:archival_object) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/archival_objects 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_objects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_objects?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_objects?all_ids=true"
  

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



## [:POST] /repositories/:repo_id/archival_objects/:id 




  
  

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
"ref_id":"T176NHY",
"level":"series",
"title":"Archival Object Title: 368",
"resource":{ "ref":"/repositories/2/resources/158"}}' \
  "http://localhost:8089/repositories/2/archival_objects/1"

```

__Description__

Update an Archival Object

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:archival_object) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/archival_objects/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_objects/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get an Archival Object by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:archival_object)
	404 -- Not found



## [:DELETE] /repositories/:repo_id/archival_objects/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/archival_objects/1"

```

__Description__

Delete an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/archival_objects/:id/accept_children 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/accept_children?children=MOHVX&position=1"

```

__Description__

Move existing Archival Objects to become children of an Archival Object

__Parameters__


	[String] children (Optional) -- The children to move to the Archival Object

	Integer id -- The ID of the Archival Object to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/archival_objects/:id/children 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_objects/1/children"
  

```

__Description__

Get the children of an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of archival object references
	404 -- Not found



## [:POST] /repositories/:repo_id/archival_objects/:id/children 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/archival_objects/1/children"

```

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



## [:POST] /repositories/:repo_id/archival_objects/:id/parent 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/parent?parent=1&position=1"

```

__Description__

Set the parent/position of an Archival Object in a tree

__Parameters__


	Integer id -- The ID of the record

	Integer parent (Optional) -- The parent of this node in the tree

	Integer position (Optional) -- The position of this node in the tree

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/archival_objects/:id/previous 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/archival_objects/1/previous"
  

```

__Description__

Get the previous record in the tree for an Archival Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:archival_object)
	404 -- No previous node



## [:POST] /repositories/:repo_id/archival_objects/:id/suppressed 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/suppressed?suppressed=true"

```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## [:POST] /repositories/:repo_id/assessment_attribute_definitions 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/assessment_attribute_definitions"

```

__Description__

Update this repository's assessment attribute definitions

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	JSONModel(:assessment_attribute_definitions) <request body> -- The assessment attribute definitions

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /repositories/:repo_id/assessment_attribute_definitions 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/assessment_attribute_definitions"
  

```

__Description__

Get this repository's assessment attribute definitions

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:assessment_attribute_definitions)



## [:POST] /repositories/:repo_id/assessments 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/assessments"

```

__Description__

Create an Assessment

__Parameters__


	JSONModel(:assessment) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## [:GET] /repositories/:repo_id/assessments 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/assessments?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/assessments?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/assessments?all_ids=true"
  

```

__Description__

Get a list of Assessments for a Repository

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

	200 -- [(:assessment)]



## [:POST] /repositories/:repo_id/assessments/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/assessments/1"

```

__Description__

Update an Assessment

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:assessment) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /repositories/:repo_id/assessments/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/assessments/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get an Assessment by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:assessment)



## [:DELETE] /repositories/:repo_id/assessments/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/assessments/1"

```

__Description__

Delete an Assessment

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/batch_imports 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"body_stream"' \
  "http://localhost:8089/repositories/2/batch_imports?migration=OPOEU&skip_results=true"

```

__Description__

Import a batch of records

__Parameters__


	body_stream batch_import -- The batch of records

	Integer repo_id -- The Repository ID -- The Repository must exist

	String migration (Optional) -- Param to indicate we are using a migrator

	RESTHelpers::BooleanParam skip_results (Optional) -- If true, don't return the list of created record URIs

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}



## [:POST] /repositories/:repo_id/classification_terms 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification_term",
"publish":true,
"path_from_root":[],
"linked_records":[],
"identifier":"O79657BA",
"title":"Classification Title: 370",
"description":"Description: 277",
"classification":{ "ref":"/repositories/2/classifications/12"}}' \
  "http://localhost:8089/repositories/2/classification_terms"

```

__Description__

Create a Classification Term

__Parameters__


	JSONModel(:classification_term) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/classification_terms 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classification_terms?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classification_terms?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classification_terms?all_ids=true"
  

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



## [:POST] /repositories/:repo_id/classification_terms/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification_term",
"publish":true,
"path_from_root":[],
"linked_records":[],
"identifier":"O79657BA",
"title":"Classification Title: 370",
"description":"Description: 277",
"classification":{ "ref":"/repositories/2/classifications/12"}}' \
  "http://localhost:8089/repositories/2/classification_terms/1"

```

__Description__

Update a Classification Term

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:classification_term) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/classification_terms/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classification_terms/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Classification Term by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:classification_term)
	404 -- Not found



## [:DELETE] /repositories/:repo_id/classification_terms/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/classification_terms/1"

```

__Description__

Delete a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/classification_terms/:id/accept_children 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/classification_terms/1/accept_children?children=1352VJP&position=1"

```

__Description__

Move existing Classification Terms to become children of another Classification Term

__Parameters__


	[String] children (Optional) -- The children to move to the Classification Term

	Integer id -- The ID of the Classification Term to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/classification_terms/:id/children 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classification_terms/1/children"
  

```

__Description__

Get the children of a Classification Term

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- a list of classification term references
	404 -- Not found



## [:POST] /repositories/:repo_id/classification_terms/:id/parent 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/classification_terms/1/parent?parent=1&position=1"

```

__Description__

Set the parent/position of a Classification Term in a tree

__Parameters__


	Integer id -- The ID of the record

	Integer parent (Optional) -- The parent of this node in the tree

	Integer position (Optional) -- The position of this node in the tree

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:POST] /repositories/:repo_id/classifications 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification",
"publish":true,
"path_from_root":[],
"linked_records":[],
"identifier":"M342726M857",
"title":"Classification Title: 369",
"description":"Description: 276"}' \
  "http://localhost:8089/repositories/2/classifications"

```

__Description__

Create a Classification

__Parameters__


	JSONModel(:classification) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/classifications 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classifications?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classifications?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classifications?all_ids=true"
  

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



## [:GET] /repositories/:repo_id/classifications/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classifications/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:classification)



## [:POST] /repositories/:repo_id/classifications/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification",
"publish":true,
"path_from_root":[],
"linked_records":[],
"identifier":"M342726M857",
"title":"Classification Title: 369",
"description":"Description: 276"}' \
  "http://localhost:8089/repositories/2/classifications/1"

```

__Description__

Update a Classification

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:classification) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:DELETE] /repositories/:repo_id/classifications/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/classifications/1"

```

__Description__

Delete a Classification

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/classifications/:id/accept_children 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/classifications/1/accept_children?children=226A598U225&position=1"

```

__Description__

Move existing Classification Terms to become children of a Classification

__Parameters__


	[String] children (Optional) -- The children to move to the Classification

	Integer id -- The ID of the Classification to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/classifications/:id/tree 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classifications/1/tree"
  

```

__Description__

Get a Classification tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK



## [:GET] /repositories/:repo_id/classifications/:id/tree/node 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classifications/1/tree/node?node_uri=OYD541O&published_only=true"
  

```

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



## [:GET] /repositories/:repo_id/classifications/:id/tree/node_from_root 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classifications/1/tree/node_from_root?node_ids=1&published_only=true"
  

```

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



## [:GET] /repositories/:repo_id/classifications/:id/tree/root 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classifications/1/tree/root?published_only=true"
  

```

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



## [:GET] /repositories/:repo_id/classifications/:id/tree/waypoint 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/classifications/1/tree/waypoint?offset=1&parent_node=FUK236O&published_only=true"
  

```

__Description__

Fetch the record slice for a given tree waypoint

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer offset -- The page of records to return

	String parent_node (Optional) -- The URI of the parent of this waypoint (none for the root record)

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent



## [:GET] /repositories/:repo_id/collection_management/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/collection_management/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Collection Management Record by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:collection_management)



## [:POST] /repositories/:repo_id/component_transfers 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/component_transfers?target_resource=VU450KH&component=E221I290K"

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



## [:GET] /repositories/:repo_id/current_preferences 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/current_preferences"
  

```

__Description__

Get the Preferences records for the current repository and user.

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {(:preference)}



## [:POST] /repositories/:repo_id/default_values/:record_type 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/default_values/1"

```

__Description__

Save defaults for a record type

__Parameters__


	JSONModel(:default_values) <request body> -- The default values set

	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/default_values/:record_type 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/default_values/1"
  

```

__Description__

Get default values for a record type

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:POST] /repositories/:repo_id/digital_object_components 




  
  

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
"component_id":"U288TDQ",
"title":"Digital Object Component Title: 373",
"digital_object":{ "ref":"/repositories/2/digital_objects/57"},
"position":10,
"has_unpublished_ancestor":true}' \
  "http://localhost:8089/repositories/2/digital_object_components"

```

__Description__

Create an Digital Object Component

__Parameters__


	JSONModel(:digital_object_component) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/digital_object_components 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_object_components?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_object_components?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_object_components?all_ids=true"
  

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



## [:POST] /repositories/:repo_id/digital_object_components/:id 




  
  

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
"component_id":"U288TDQ",
"title":"Digital Object Component Title: 373",
"digital_object":{ "ref":"/repositories/2/digital_objects/57"},
"position":10,
"has_unpublished_ancestor":true}' \
  "http://localhost:8089/repositories/2/digital_object_components/1"

```

__Description__

Update an Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:digital_object_component) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/digital_object_components/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_object_components/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get an Digital Object Component by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:digital_object_component)
	404 -- Not found



## [:DELETE] /repositories/:repo_id/digital_object_components/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/digital_object_components/1"

```

__Description__

Delete a Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/digital_object_components/:id/accept_children 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_object_components/1/accept_children?children=887204XGB&position=1"

```

__Description__

Move existing Digital Object Components to become children of a Digital Object Component

__Parameters__


	[String] children (Optional) -- The children to move to the Digital Object Component

	Integer id -- The ID of the Digital Object Component to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}



## [:POST] /repositories/:repo_id/digital_object_components/:id/children 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/digital_object_components/1/children"

```

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



## [:GET] /repositories/:repo_id/digital_object_components/:id/children 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_object_components/1/children"
  

```

__Description__

Get the children of an Digital Object Component

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:digital_object_component)]
	404 -- Not found



## [:POST] /repositories/:repo_id/digital_object_components/:id/parent 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_object_components/1/parent?parent=1&position=1"

```

__Description__

Set the parent/position of an Digital Object Component in a tree

__Parameters__


	Integer id -- The ID of the record

	Integer parent (Optional) -- The parent of this node in the tree

	Integer position (Optional) -- The position of this node in the tree

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:POST] /repositories/:repo_id/digital_object_components/:id/suppressed 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_object_components/1/suppressed?suppressed=true"

```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## [:POST] /repositories/:repo_id/digital_objects 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"part",
"number":"8",
"extent_type":"leaves",
"dimensions":"215S330VA",
"physical_details":"BBT607H"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"inclusive",
"label":"creation",
"begin":"1992-07-13",
"end":"1992-07-13",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"122G185R310"},
{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"1992-11-17",
"end":"1992-11-17",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"Y20852B84"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"174CT338",
"use_statement":"video-service",
"xlink_actuate_attribute":"none",
"xlink_show_attribute":"replace",
"file_format_name":"aiff",
"file_format_version":"PYSVJ",
"file_size_bytes":24,
"checksum":"FJJCD",
"checksum_method":"sha-384",
"publish":true},
{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"KHC984C",
"use_statement":"text-ocr-unedited",
"xlink_actuate_attribute":"other",
"xlink_show_attribute":"new",
"file_format_name":"jpeg",
"file_format_version":"856WDHE",
"file_size_bytes":55,
"checksum":"985QSS624",
"checksum_method":"sha-256",
"publish":true},
{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"847GJ99T",
"use_statement":"text-tei-translated",
"xlink_actuate_attribute":"onLoad",
"xlink_show_attribute":"new",
"file_format_name":"txt",
"file_format_version":"VK815431I",
"file_size_bytes":23,
"checksum":"442905144D805",
"checksum_method":"sha-256",
"publish":true}],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 372",
"language":"kaa",
"digital_object_id":"NOES285"}' \
  "http://localhost:8089/repositories/2/digital_objects"

```

__Description__

Create a Digital Object

__Parameters__


	JSONModel(:digital_object) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/digital_objects 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects?all_ids=true"
  

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



## [:GET] /repositories/:repo_id/digital_objects/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:digital_object)



## [:POST] /repositories/:repo_id/digital_objects/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"part",
"number":"8",
"extent_type":"leaves",
"dimensions":"215S330VA",
"physical_details":"BBT607H"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"inclusive",
"label":"creation",
"begin":"1992-07-13",
"end":"1992-07-13",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"122G185R310"},
{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"1992-11-17",
"end":"1992-11-17",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"Y20852B84"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"174CT338",
"use_statement":"video-service",
"xlink_actuate_attribute":"none",
"xlink_show_attribute":"replace",
"file_format_name":"aiff",
"file_format_version":"PYSVJ",
"file_size_bytes":24,
"checksum":"FJJCD",
"checksum_method":"sha-384",
"publish":true},
{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"KHC984C",
"use_statement":"text-ocr-unedited",
"xlink_actuate_attribute":"other",
"xlink_show_attribute":"new",
"file_format_name":"jpeg",
"file_format_version":"856WDHE",
"file_size_bytes":55,
"checksum":"985QSS624",
"checksum_method":"sha-256",
"publish":true},
{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"847GJ99T",
"use_statement":"text-tei-translated",
"xlink_actuate_attribute":"onLoad",
"xlink_show_attribute":"new",
"file_format_name":"txt",
"file_format_version":"VK815431I",
"file_size_bytes":23,
"checksum":"442905144D805",
"checksum_method":"sha-256",
"publish":true}],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 372",
"language":"kaa",
"digital_object_id":"NOES285"}' \
  "http://localhost:8089/repositories/2/digital_objects/1"

```

__Description__

Update a Digital Object

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:digital_object) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:DELETE] /repositories/:repo_id/digital_objects/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/digital_objects/1"

```

__Description__

Delete a Digital Object

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/digital_objects/:id/accept_children 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/accept_children?children=11M791SO&position=1"

```

__Description__

Move existing Digital Object components to become children of a Digital Object

__Parameters__


	[String] children (Optional) -- The children to move to the Digital Object

	Integer id -- The ID of the Digital Object to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}



## [:POST] /repositories/:repo_id/digital_objects/:id/children 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/digital_objects/1/children"

```

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



## [:POST] /repositories/:repo_id/digital_objects/:id/publish 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/publish"

```

__Description__

Publish a digital object and all its sub-records and components

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:POST] /repositories/:repo_id/digital_objects/:id/suppressed 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/suppressed?suppressed=true"

```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## [:POST] /repositories/:repo_id/digital_objects/:id/transfer 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/transfer?target_repo=365418SON"

```

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved



## [:GET] /repositories/:repo_id/digital_objects/:id/tree 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/1/tree"
  

```

__Description__

Get a Digital Object tree

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK



## [:GET] /repositories/:repo_id/digital_objects/:id/tree/node 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/1/tree/node?node_uri=TAV230F&published_only=true"
  

```

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



## [:GET] /repositories/:repo_id/digital_objects/:id/tree/node_from_root 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/1/tree/node_from_root?node_ids=1&published_only=true"
  

```

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



## [:GET] /repositories/:repo_id/digital_objects/:id/tree/root 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/1/tree/root?published_only=true"
  

```

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



## [:GET] /repositories/:repo_id/digital_objects/:id/tree/waypoint 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/1/tree/waypoint?offset=1&parent_node=17753112477N&published_only=true"
  

```

__Description__

Fetch the record slice for a given tree waypoint

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer offset -- The page of records to return

	String parent_node (Optional) -- The URI of the parent of this waypoint (none for the root record)

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent



## [:GET] /repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/dublin_core/1.:fmt/metadata"
  

```

__Description__

Get metadata for a Dublin Core export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/digital_objects/dublin_core/:id.xml 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/dublin_core/1.xml"
  

```

__Description__

Get a Dublin Core representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)



## [:GET] /repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/mets/1.:fmt/metadata"
  

```

__Description__

Get metadata for a METS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/digital_objects/mets/:id.xml 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/mets/1.xml?dmd=U850CNS"
  

```

__Description__

Get a METS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	String dmd (Optional) -- DMD Scheme to use

__Returns__

	200 -- (:digital_object)



## [:GET] /repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/mods/1.:fmt/metadata"
  

```

__Description__

Get metadata for a MODS export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/digital_objects/mods/:id.xml 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/digital_objects/mods/1.xml"
  

```

__Description__

Get a MODS representation of a Digital Object 

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:digital_object)



## [:POST] /repositories/:repo_id/events 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"event",
"external_ids":[],
"external_documents":[],
"linked_agents":[{ "ref":"/agents/people/335",
"role":"recipient"}],
"linked_records":[{ "ref":"/repositories/2/accessions/102",
"role":"requested"}],
"date":{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1973-09-28",
"end":"1973-09-28",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"X403141YD"},
"event_type":"contribution"}' \
  "http://localhost:8089/repositories/2/events"

```

__Description__

Create an Event

__Parameters__


	JSONModel(:event) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/events 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/events?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/events?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/events?all_ids=true"
  

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



## [:POST] /repositories/:repo_id/events/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"event",
"external_ids":[],
"external_documents":[],
"linked_agents":[{ "ref":"/agents/people/335",
"role":"recipient"}],
"linked_records":[{ "ref":"/repositories/2/accessions/102",
"role":"requested"}],
"date":{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1973-09-28",
"end":"1973-09-28",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"X403141YD"},
"event_type":"contribution"}' \
  "http://localhost:8089/repositories/2/events/1"

```

__Description__

Update an Event

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:event) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /repositories/:repo_id/events/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/events/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get an Event by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:event)
	404 -- Not found



## [:DELETE] /repositories/:repo_id/events/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/events/1"

```

__Description__

Delete an event record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/events/:id/suppressed 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/events/1/suppressed?suppressed=true"

```

__Description__

Suppress this record from non-managers

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## [:GET] /repositories/:repo_id/find_by_id/archival_objects 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/find_by_id/archival_objects?ref_id=CNF305C&component_id=GX411D464&resolve[]=[record_types, to_resolve]"
  

```

__Description__

Find Archival Objects by ref_id or component_id

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] ref_id (Optional) -- A set of record Ref IDs

	[String] component_id (Optional) -- A set of record component IDs

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- JSON array of refs



## [:GET] /repositories/:repo_id/find_by_id/digital_object_components 



  
  
    
      
        
      
    
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/find_by_id/digital_object_components?component_id=JDH273288&resolve[]=[record_types, to_resolve]"
  

```

__Description__

Find Digital Object Components by component_id

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] component_id (Optional) -- A set of record component IDs

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- JSON array of refs



## [:GET] /repositories/:repo_id/find_by_id/digital_objects 



  
  
    
      
        
      
    
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/find_by_id/digital_objects?digital_object_id=OS620X420&resolve[]=[record_types, to_resolve]"
  

```

__Description__

Find Digital Objects by digital_object_id

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] digital_object_id (Optional) -- A set of digital object IDs

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- JSON array of refs



## [:GET] /repositories/:repo_id/find_by_id/resources 



  
  
    
      
        
      
    
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/find_by_id/resources?identifier=133EW795N&resolve[]=[record_types, to_resolve]"
  

```

__Description__

Find Resources by their identifiers

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] identifier (Optional) -- A 4-part identifier expressed as JSON array (of up to 4 strings)

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- JSON array of refs



## [:POST] /repositories/:repo_id/groups 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 282",
"member_usernames":[],
"grants_permissions":[],
"group_code":"BPQMN"}' \
  "http://localhost:8089/repositories/2/groups"

```

__Description__

Create a group within a repository

__Parameters__


	JSONModel(:group) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- conflict



## [:GET] /repositories/:repo_id/groups 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/groups?group_code=252PPG57"
  

```

__Description__

Get a list of groups for a repository

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String group_code (Optional) -- Get groups by group code

__Returns__

	200 -- [(:resource)]



## [:POST] /repositories/:repo_id/groups/:id 



  
  
    
      
        
      
    
  
  

  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 282",
"member_usernames":[],
"grants_permissions":[],
"group_code":"BPQMN"}' \
  "http://localhost:8089/repositories/2/groups/1?with_members=true"

```

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



## [:GET] /repositories/:repo_id/groups/:id 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/groups/1?with_members=true"
  

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



## [:DELETE] /repositories/:repo_id/groups/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/groups/1"

```

__Description__

Delete a group by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:group)
	404 -- Not found



## [:POST] /repositories/:repo_id/jobs 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"job",
"status":"queued",
"job":{ "jsonmodel_type":"import_job",
"filenames":["82RXP74",
"WF574S255",
"HOAM298",
"IN27Q960"],
"import_type":"marcxml"}}' \
  "http://localhost:8089/repositories/2/jobs"

```

__Description__

Create a new job

__Parameters__


	JSONModel(:job) <request body> -- The job object

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /repositories/:repo_id/jobs 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs?all_ids=true"
  

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



## [:DELETE] /repositories/:repo_id/jobs/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/jobs/1"

```

__Description__

Delete a Job

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:GET] /repositories/:repo_id/jobs/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Job by ID

__Parameters__


	Integer id -- The ID of the record

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:job)



## [:POST] /repositories/:repo_id/jobs/:id/cancel 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/jobs/1/cancel"

```

__Description__

Cancel a Job

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /repositories/:repo_id/jobs/:id/log 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/1/log?offset=NonNegativeInteger"
  

```

__Description__

Get a Job's log by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::NonNegativeInteger offset -- The byte offset of the log file to show

__Returns__

	200 -- The section of the import log between 'offset' and the end of file



## [:GET] /repositories/:repo_id/jobs/:id/output_files 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/1/output_files"
  

```

__Description__

Get a list of Job's output files by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- An array of output files



## [:GET] /repositories/:repo_id/jobs/:id/output_files/:file_id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/1/output_files/1"
  

```

__Description__

Get a Job's output file by ID

__Parameters__


	Integer id -- The ID of the record

	Integer file_id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- Returns the file



## [:GET] /repositories/:repo_id/jobs/:id/records 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/1/records?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/1/records?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/1/records?all_ids=true"
  

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



## [:GET] /repositories/:repo_id/jobs/active 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/active?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a list of all active Jobs for a Repository

__Parameters__


	[String] resolve (Optional) -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:job)]



## [:GET] /repositories/:repo_id/jobs/archived 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/archived?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/archived?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/archived?all_ids=true"
  

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

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:job)]



## [:GET] /repositories/:repo_id/jobs/import_types 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/jobs/import_types"
  

```

__Description__

List all supported import job types

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- A list of supported import types



## [:POST] /repositories/:repo_id/jobs_with_files 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/jobs_with_files?job={"jsonmodel_type"=>"job", "status"=>"queued", "job"=>{"jsonmodel_type"=>"import_job", "filenames"=>["82RXP74", "WF574S255", "HOAM298", "IN27Q960"], "import_type"=>"marcxml"}}&files=UploadFile"

```

__Description__

Create a new job and post input files

__Parameters__


	JSONModel(:job) job -- 

	[RESTHelpers::UploadFile] files -- 

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /repositories/:repo_id/preferences 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"preference",
"defaults":{ "jsonmodel_type":"defaults",
"default_values":false,
"note_order":[],
"show_suppressed":false,
"publish":false}}' \
  "http://localhost:8089/repositories/2/preferences"

```

__Description__

Create a Preferences record

__Parameters__


	JSONModel(:preference) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/preferences 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/preferences?user_id=1"
  

```

__Description__

Get a list of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer user_id (Optional) -- The username to retrieve defaults for

__Returns__

	200 -- [(:preference)]



## [:GET] /repositories/:repo_id/preferences/:id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/preferences/1"
  

```

__Description__

Get a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:preference)



## [:POST] /repositories/:repo_id/preferences/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"preference",
"defaults":{ "jsonmodel_type":"defaults",
"default_values":false,
"note_order":[],
"show_suppressed":false,
"publish":false}}' \
  "http://localhost:8089/repositories/2/preferences/1"

```

__Description__

Update a Preferences record

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:preference) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:DELETE] /repositories/:repo_id/preferences/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/preferences/1"

```

__Description__

Delete a Preferences record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:GET] /repositories/:repo_id/preferences/defaults 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/preferences/defaults?username=813JLC147"
  

```

__Description__

Get the default set of Preferences for a Repository and optionally a user

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String username (Optional) -- The username to retrieve defaults for

__Returns__

	200 -- (defaults)



## [:POST] /repositories/:repo_id/rde_templates 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/rde_templates"

```

__Description__

Create an RDE template

__Parameters__


	JSONModel(:rde_template) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/rde_templates 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/rde_templates"
  

```

__Description__

Get a list of RDE Templates

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- [(:rde_template)]



## [:GET] /repositories/:repo_id/rde_templates/:id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/rde_templates/1"
  

```

__Description__

Get an RDE template record

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:rde_template)



## [:DELETE] /repositories/:repo_id/rde_templates/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/rde_templates/1"

```

__Description__

Delete an RDE Template

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/required_fields/:record_type 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/required_fields/1"

```

__Description__

Require fields for a record type

__Parameters__


	JSONModel(:required_fields) <request body> -- The fields required

	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/required_fields/:record_type 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/required_fields/1"
  

```

__Description__

Get required fields for a record type

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String record_type -- 

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/resource_descriptions/:id.:fmt/metadata 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resource_descriptions/1.:fmt/metadata?fmt=800IKI191"
  

```

__Description__

Get export metadata for a Resource Description

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	String fmt (Optional) -- Format of the request

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/resource_descriptions/:id.pdf 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resource_descriptions/1.pdf?include_unpublished=true&include_daos=true&numbered_cs=true&print_pdf=true&ead3=true"
  

```

__Description__

Get an EAD representation of a Resource

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam include_unpublished (Optional) -- Include unpublished records

	RESTHelpers::BooleanParam include_daos (Optional) -- Include digital objects in dao tags

	RESTHelpers::BooleanParam numbered_cs (Optional) -- Use numbered <c> tags in ead

	RESTHelpers::BooleanParam print_pdf (Optional) -- Print EAD to pdf

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam ead3 (Optional) -- Export using EAD3 schema

__Returns__

	200 -- (:resource)



## [:GET] /repositories/:repo_id/resource_descriptions/:id.xml 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resource_descriptions/1.xml?include_unpublished=true&include_daos=true&numbered_cs=true&print_pdf=true&ead3=true"
  

```

__Description__

Get an EAD representation of a Resource

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam include_unpublished (Optional) -- Include unpublished records

	RESTHelpers::BooleanParam include_daos (Optional) -- Include digital objects in dao tags

	RESTHelpers::BooleanParam numbered_cs (Optional) -- Use numbered <c> tags in ead

	RESTHelpers::BooleanParam print_pdf (Optional) -- Print EAD to pdf

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam ead3 (Optional) -- Export using EAD3 schema

__Returns__

	200 -- (:resource)



## [:GET] /repositories/:repo_id/resource_labels/:id.:fmt/metadata 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resource_labels/1.:fmt/metadata"
  

```

__Description__

Get export metadata for Resource labels

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/resource_labels/:id.tsv 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resource_labels/1.tsv"
  

```

__Description__

Get a tsv list of printable labels for a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:resource)



## [:POST] /repositories/:repo_id/resources 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"resource",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"whole",
"number":"4",
"extent_type":"volumes",
"dimensions":"705JT549L",
"physical_details":"V61260MB"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"1991-05-10",
"end":"1991-05-10",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"JUYVA"},
{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1993-07-27",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"765JKC774"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"670K846I136",
"description":"EG496H377"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"books",
"sub_container":{ "jsonmodel_type":"sub_container",
"top_container":{ "ref":"/repositories/2/top_containers/182"},
"type_2":"folder",
"indicator_2":"42347FIF",
"type_3":"case",
"indicator_3":"868YHP249"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>149</emph>",
"id_0":"H1924A323",
"level":"class",
"language":"mlg",
"ead_id":"90JY154S",
"finding_aid_date":"839NQ36042",
"finding_aid_series_statement":"695621677FP",
"finding_aid_note":"LOLPD",
"ead_location":"VX325XI"}' \
  "http://localhost:8089/repositories/2/resources"

```

__Description__

Create a Resource

__Parameters__


	JSONModel(:resource) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /repositories/:repo_id/resources 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources?all_ids=true"
  

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



## [:GET] /repositories/:repo_id/resources/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:resource)



## [:POST] /repositories/:repo_id/resources/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"resource",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"whole",
"number":"4",
"extent_type":"volumes",
"dimensions":"705JT549L",
"physical_details":"V61260MB"}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"1991-05-10",
"end":"1991-05-10",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"JUYVA"},
{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1993-07-27",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"765JKC774"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"670K846I136",
"description":"EG496H377"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"books",
"sub_container":{ "jsonmodel_type":"sub_container",
"top_container":{ "ref":"/repositories/2/top_containers/182"},
"type_2":"folder",
"indicator_2":"42347FIF",
"type_3":"case",
"indicator_3":"868YHP249"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>149</emph>",
"id_0":"H1924A323",
"level":"class",
"language":"mlg",
"ead_id":"90JY154S",
"finding_aid_date":"839NQ36042",
"finding_aid_series_statement":"695621677FP",
"finding_aid_note":"LOLPD",
"ead_location":"VX325XI"}' \
  "http://localhost:8089/repositories/2/resources/1"

```

__Description__

Update a Resource

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:resource) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:DELETE] /repositories/:repo_id/resources/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/resources/1"

```

__Description__

Delete a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/resources/:id/accept_children 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/accept_children?children=K96444E573&position=1"

```

__Description__

Move existing Archival Objects to become children of a Resource

__Parameters__


	[String] children (Optional) -- The children to move to the Resource

	Integer id -- The ID of the Resource to move children to

	Integer position -- The index for the first child to be moved to

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	409 -- {:error => (description of error)}



## [:POST] /repositories/:repo_id/resources/:id/children 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/resources/1/children"

```

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



## [:GET] /repositories/:repo_id/resources/:id/models_in_graph 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/1/models_in_graph"
  

```

__Description__

Get a list of record types in the graph of a resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK



## [:GET] /repositories/:repo_id/resources/:id/ordered_records 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/1/ordered_records"
  

```

__Description__

Get the list of URIs of this published resource and all published archival objects contained within.Ordered by tree order (i.e. if you fully expanded the record tree and read from top to bottom)

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- JSONModel(:resource_ordered_records)



## [:POST] /repositories/:repo_id/resources/:id/publish 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/publish"

```

__Description__

Publish a resource and all its sub-records and components

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:POST] /repositories/:repo_id/resources/:id/suppressed 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/suppressed?suppressed=true"

```

__Description__

Suppress this record

__Parameters__


	Integer id -- The ID of the record

	RESTHelpers::BooleanParam suppressed -- Suppression state

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## [:GET] /repositories/:repo_id/resources/:id/top_containers 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/1/top_containers?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get Top Containers linked to a published resource and published archival ojbects contained within.

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- a list of linked top containers
	404 -- Not found



## [:POST] /repositories/:repo_id/resources/:id/transfer 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/transfer?target_repo=HI206QW"

```

__Description__

Transfer this record to a different repository

__Parameters__


	Integer id -- The ID of the record

	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved



## [:GET] /repositories/:repo_id/resources/:id/tree 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/1/tree?limit_to=863159885U689"
  

```

__Description__

Get a Resource tree

__Parameters__


	Integer id -- The ID of the record

	String limit_to (Optional) -- An Archival Object URI or 'root'

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- OK



## [:GET] /repositories/:repo_id/resources/:id/tree/node 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/1/tree/node?node_uri=534FDD378&published_only=true"
  

```

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



## [:GET] /repositories/:repo_id/resources/:id/tree/node_from_root 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/1/tree/node_from_root?node_ids=1&published_only=true"
  

```

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



## [:GET] /repositories/:repo_id/resources/:id/tree/root 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/1/tree/root?published_only=true"
  

```

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



## [:GET] /repositories/:repo_id/resources/:id/tree/waypoint 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/1/tree/waypoint?offset=1&parent_node=EHV219986&published_only=true"
  

```

__Description__

Fetch the record slice for a given tree waypoint

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	Integer offset -- The page of records to return

	String parent_node (Optional) -- The URI of the parent of this waypoint (none for the root record)

	RESTHelpers::BooleanParam published_only -- Whether to restrict to published/unsuppressed items

__Returns__

	200 -- Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent



## [:GET] /repositories/:repo_id/resources/marc21/:id.:fmt/metadata 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/marc21/1.:fmt/metadata?include_unpublished_marc=true"
  

```

__Description__

Get metadata for a MARC21 export

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam include_unpublished_marc (Optional) -- Include unpublished notes

__Returns__

	200 -- The export metadata



## [:GET] /repositories/:repo_id/resources/marc21/:id.xml 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/resources/marc21/1.xml?include_unpublished_marc=true"
  

```

__Description__

Get a MARC 21 representation of a Resource

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	RESTHelpers::BooleanParam include_unpublished_marc (Optional) -- Include unpublished notes

__Returns__

	200 -- (:resource)



## [:GET, :POST] /repositories/:repo_id/search 




  

```shell 
    
      
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"HNON877"' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"CS70NS"' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"290736400O"' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BLYW372"' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"C206DV75"' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"Q355T747Y"' \
  "http://localhost:8089/repositories/2/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"E313G526F"' \
  "http://localhost:8089/repositories/2/search"
  

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

	String q (Optional) -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq (Optional) -- A json string containing the advanced query

	[String] type (Optional) -- The record type to search (defaults to all types if not specified)

	String sort (Optional) -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet (Optional) -- The list of the fields to produce facets for

	Integer facet_mincount (Optional) -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter (Optional) -- A json string containing the advanced query to filter by

	[String] exclude (Optional) -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl (Optional) -- Whether to use highlighting

	String root_record (Optional) -- Search within a collection of records (defined by the record at the root of the tree)

	String dt (Optional) -- Format to return (JSON default)

__Returns__

	200 -- 



## [:POST] /repositories/:repo_id/top_containers 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"top_container",
"active_restrictions":[],
"container_locations":[],
"series":[],
"collection":[],
"indicator":"565997T292H",
"type":"box",
"barcode":"e8b06ef84d6dd55db72a6583bd93db6d",
"ils_holding_id":"YTKHG",
"ils_item_id":"972443IL585",
"exported_to_ils":"2018-10-16T08:29:34-07:00"}' \
  "http://localhost:8089/repositories/2/top_containers"

```

__Description__

Create a top container

__Parameters__


	JSONModel(:top_container) <request body> -- The record to create

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## [:GET] /repositories/:repo_id/top_containers 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/top_containers?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/top_containers?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/top_containers?all_ids=true"
  

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



## [:POST] /repositories/:repo_id/top_containers/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"top_container",
"active_restrictions":[],
"container_locations":[],
"series":[],
"collection":[],
"indicator":"565997T292H",
"type":"box",
"barcode":"e8b06ef84d6dd55db72a6583bd93db6d",
"ils_holding_id":"YTKHG",
"ils_item_id":"972443IL585",
"exported_to_ils":"2018-10-16T08:29:34-07:00"}' \
  "http://localhost:8089/repositories/2/top_containers/1"

```

__Description__

Update a top container

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:top_container) <request body> -- The updated record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /repositories/:repo_id/top_containers/:id 



  
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/top_containers/1?resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a top container by ID

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- (:top_container)



## [:DELETE] /repositories/:repo_id/top_containers/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/repositories/2/top_containers/1"

```

__Description__

Delete a top container

__Parameters__


	Integer id -- The ID of the record

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- deleted



## [:POST] /repositories/:repo_id/top_containers/batch/container_profile 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/top_containers/batch/container_profile?ids=1&container_profile_uri=327YQ259J"

```

__Description__

Update container profile for a batch of top containers

__Parameters__


	[Integer] ids -- 

	String container_profile_uri -- The uri of the container profile

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /repositories/:repo_id/top_containers/batch/ils_holding_id 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/top_containers/batch/ils_holding_id?ids=1&ils_holding_id=FOG461531"

```

__Description__

Update ils_holding_id for a batch of top containers

__Parameters__


	[Integer] ids -- 

	String ils_holding_id -- Value to set for ils_holding_id

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /repositories/:repo_id/top_containers/batch/location 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/top_containers/batch/location?ids=1&location_uri=629MIN517"

```

__Description__

Update location for a batch of top containers

__Parameters__


	[Integer] ids -- 

	String location_uri -- The uri of the location

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /repositories/:repo_id/top_containers/bulk/barcodes 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"SY841EK"' \
  "http://localhost:8089/repositories/2/top_containers/bulk/barcodes"

```

__Description__

Bulk update barcodes

__Parameters__


	String <request body> -- JSON string containing barcode data {uri=>barcode}

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:POST] /repositories/:repo_id/top_containers/bulk/locations 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"UWEMH"' \
  "http://localhost:8089/repositories/2/top_containers/bulk/locations"

```

__Description__

Bulk update locations

__Parameters__


	String <request body> -- JSON string containing location data {container_uri=>location_uri}

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /repositories/:repo_id/top_containers/search 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/top_containers/search?q=VTN213981&aq=["Example Missing"]&type=707A577XR&sort=NFL128R&facet=291NKSV&facet_mincount=1&filter=["Example Missing"]&exclude=EVLKO&hl=true&root_record=290NG805151&dt=415NHOF"
  

```

__Description__

Search for top containers

__Parameters__


	Integer repo_id -- The Repository ID -- The Repository must exist

	String q (Optional) -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq (Optional) -- A json string containing the advanced query

	[String] type (Optional) -- The record type to search (defaults to all types if not specified)

	String sort (Optional) -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet (Optional) -- The list of the fields to produce facets for

	Integer facet_mincount (Optional) -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter (Optional) -- A json string containing the advanced query to filter by

	[String] exclude (Optional) -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl (Optional) -- Whether to use highlighting

	String root_record (Optional) -- Search within a collection of records (defined by the record at the root of the tree)

	String dt (Optional) -- Format to return (JSON default)

__Returns__

	200 -- [(:top_container)]



## [:POST] /repositories/:repo_id/transfer 



  
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/transfer?target_repo=I72725MX"

```

__Description__

Transfer this record to a different repository

__Parameters__


	String target_repo -- The URI of the target repository

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- moved



## [:GET] /repositories/:repo_id/users/:id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/2/users/1"
  

```

__Description__

Get a user's details including their groups for the current repository

__Parameters__


	Integer id -- The username id to fetch

	Integer repo_id -- The Repository ID -- The Repository must exist

__Returns__

	200 -- (:user)



## [:POST] /repositories/with_agent 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/with_agent"

```

__Description__

Create a Repository with an agent representation

__Parameters__


	JSONModel(:repository_with_agent) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}
	403 -- access_denied



## [:GET] /repositories/with_agent/:id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/with_agent/1"
  

```

__Description__

Get a Repository by ID, including its agent representation

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:repository_with_agent)
	404 -- Not found



## [:POST] /repositories/with_agent/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/with_agent/1"

```

__Description__

Update a repository with an agent representation

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:repository_with_agent) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /schemas 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/schemas"
  

```

__Description__

Get all ArchivesSpace schemas

__Parameters__


__Returns__

	200 -- ArchivesSpace (schemas)



## [:GET] /schemas/:schema 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/schemas/1"
  

```

__Description__

Get an ArchivesSpace schema

__Parameters__


	String schema -- Schema name to retrieve

__Returns__

	200 -- ArchivesSpace (:schema)
	404 -- Schema not found



## [:GET, :POST] /search 




  

```shell 
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"QUT854564"' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"832960QB989"' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"WPRHC"' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"S515SDP"' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"89463691O118"' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"QIBI16"' \
  "http://localhost:8089/search"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"10D317O160"' \
  "http://localhost:8089/search"
  

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

	String q (Optional) -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq (Optional) -- A json string containing the advanced query

	[String] type (Optional) -- The record type to search (defaults to all types if not specified)

	String sort (Optional) -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet (Optional) -- The list of the fields to produce facets for

	Integer facet_mincount (Optional) -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter (Optional) -- A json string containing the advanced query to filter by

	[String] exclude (Optional) -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl (Optional) -- Whether to use highlighting

	String root_record (Optional) -- Search within a collection of records (defined by the record at the root of the tree)

	String dt (Optional) -- Format to return (JSON default)

__Returns__

	200 -- 



## [:GET] /search/location_profile 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/location_profile?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/location_profile?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/location_profile?all_ids=true"
  

```

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

	String q (Optional) -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq (Optional) -- A json string containing the advanced query

	[String] type (Optional) -- The record type to search (defaults to all types if not specified)

	String sort (Optional) -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet (Optional) -- The list of the fields to produce facets for

	Integer facet_mincount (Optional) -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter (Optional) -- A json string containing the advanced query to filter by

	[String] exclude (Optional) -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl (Optional) -- Whether to use highlighting

	String root_record (Optional) -- Search within a collection of records (defined by the record at the root of the tree)

	String dt (Optional) -- Format to return (JSON default)

__Returns__

	200 -- 



## [:GET] /search/published_tree 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/search/published_tree?node_uri=O26QJP"
  

```

__Description__

Find the tree view for a particular archival record

__Parameters__


	String node_uri -- The URI of the archival record to find the tree view for

__Returns__

	200 -- OK
	404 -- Not found



## [:GET, :POST] /search/record_types_by_repository 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"I358D354S"' \
  "http://localhost:8089/search/record_types_by_repository?record_types=I358D354S&repo_uri=P889DUT"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"P889DUT"' \
  "http://localhost:8089/search/record_types_by_repository?record_types=I358D354S&repo_uri=P889DUT"
  

```

__Description__

Return the counts of record types of interest by repository

__Parameters__


	[String] record_types -- The list of record types to tally

	String repo_uri (Optional) -- An optional repository URI.  If given, just return counts for the single repository

__Returns__

	200 -- If repository is given, returns a map like {'record_type' => <count>}.  Otherwise, {'repo_uri' => {'record_type' => <count>}}



## [:GET, :POST] /search/records 



  
  
    
      
        
      
    
  
    
      
    
  
  

  

```shell 
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"504130V795212"' \
  "http://localhost:8089/search/records?uri=504130V795212&resolve[]=[record_types, to_resolve]"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"544412GSH"' \
  "http://localhost:8089/search/records?uri=504130V795212&resolve[]=[record_types, to_resolve]"
  

```

__Description__

Return a set of records by URI

__Parameters__


	[String] uri -- The list of record URIs to fetch

	[String] resolve (Optional) -- The list of result fields to resolve (if any)

__Returns__

	200 -- a JSON map of records



## [:GET, :POST] /search/repositories 




  

```shell 
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"NXXNN"' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"P32IAF"' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"FSGK456"' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"IE424LN"' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"HT243353J"' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BAHX208"' \
  "http://localhost:8089/search/repositories"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"6062U76741"' \
  "http://localhost:8089/search/repositories"
  

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

	String q (Optional) -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq (Optional) -- A json string containing the advanced query

	[String] type (Optional) -- The record type to search (defaults to all types if not specified)

	String sort (Optional) -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet (Optional) -- The list of the fields to produce facets for

	Integer facet_mincount (Optional) -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter (Optional) -- A json string containing the advanced query to filter by

	[String] exclude (Optional) -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl (Optional) -- Whether to use highlighting

	String root_record (Optional) -- Search within a collection of records (defined by the record at the root of the tree)

	String dt (Optional) -- Format to return (JSON default)

__Returns__

	200 -- 



## [:GET, :POST] /search/subjects 




  

```shell 
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"JIIL100"' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"416910YHD"' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"946V988Y501"' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"XIOEP"' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"702650T793492"' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"EN219A772"' \
  "http://localhost:8089/search/subjects"
    
      
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BIBLL"' \
  "http://localhost:8089/search/subjects"
  

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

	String q (Optional) -- A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml

	JSONModel(:advanced_query) aq (Optional) -- A json string containing the advanced query

	[String] type (Optional) -- The record type to search (defaults to all types if not specified)

	String sort (Optional) -- The attribute to sort and the direction e.g. &sort=title desc&...

	[String] facet (Optional) -- The list of the fields to produce facets for

	Integer facet_mincount (Optional) -- The minimum count for a facet field to be included in the response

	JSONModel(:advanced_query) filter (Optional) -- A json string containing the advanced query to filter by

	[String] exclude (Optional) -- A list of document IDs that should be excluded from results

	RESTHelpers::BooleanParam hl (Optional) -- Whether to use highlighting

	String root_record (Optional) -- Search within a collection of records (defined by the record at the root of the tree)

	String dt (Optional) -- Format to return (JSON default)

__Returns__

	200 -- 



## [:GET] /space_calculator/buildings 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/space_calculator/buildings"
  

```

__Description__

Get a Location by ID

__Parameters__


__Returns__

	200 -- Location building data as JSON



## [:GET] /space_calculator/by_building 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/space_calculator/by_building?container_profile_uri=687AY141I&building=90PPR277&floor=431S805K26&room=655678I645423&area=KCI174O"
  

```

__Description__

Calculate how many containers will fit in locations for a given building

__Parameters__


	String container_profile_uri -- The uri of the container profile

	String building -- The building to check for space in

	String floor (Optional) -- The floor to check for space in

	String room (Optional) -- The room to check for space in

	String area (Optional) -- The area to check for space in

__Returns__

	200 -- Calculation results



## [:GET] /space_calculator/by_location 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/space_calculator/by_location?container_profile_uri=DEV829M&location_uris=C492G6S"
  

```

__Description__

Calculate how many containers will fit in a list of locations

__Parameters__


	String container_profile_uri -- The uri of the container profile

	[String] location_uris -- A list of location uris to calculate space for

__Returns__

	200 -- Calculation results



## [:POST] /subjects 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"subject",
"external_ids":[],
"publish":true,
"used_within_repositories":[],
"used_within_published_repositories":[],
"terms":[{ "jsonmodel_type":"term",
"term":"Term 132",
"term_type":"occupation",
"vocabulary":"/vocabularies/156"}],
"external_documents":[],
"vocabulary":"/vocabularies/157",
"authority_id":"http://www.example-572.com",
"scope_note":"653QWRB",
"source":"aat"}' \
  "http://localhost:8089/subjects"

```

__Description__

Create a Subject

__Parameters__


	JSONModel(:subject) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## [:GET] /subjects 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/subjects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/subjects?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/subjects?all_ids=true"
  

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



## [:POST] /subjects/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"subject",
"external_ids":[],
"publish":true,
"used_within_repositories":[],
"used_within_published_repositories":[],
"terms":[{ "jsonmodel_type":"term",
"term":"Term 132",
"term_type":"occupation",
"vocabulary":"/vocabularies/156"}],
"external_documents":[],
"vocabulary":"/vocabularies/157",
"authority_id":"http://www.example-572.com",
"scope_note":"653QWRB",
"source":"aat"}' \
  "http://localhost:8089/subjects/1"

```

__Description__

Update a Subject

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:subject) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /subjects/:id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/subjects/1"
  

```

__Description__

Get a Subject by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- (:subject)



## [:DELETE] /subjects/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/subjects/1"

```

__Description__

Delete a Subject

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- deleted



## [:GET] /terms 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/terms?q=JKA640C"
  

```

__Description__

Get a list of Terms matching a prefix

__Parameters__


	String q -- The prefix to match

__Returns__

	200 -- [(:term)]



## [:GET] /update-feed 



  
  
    
      
        
      
    
  
    
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/update-feed?last_sequence=1&resolve[]=[record_types, to_resolve]"
  

```

__Description__

Get a stream of updated records

__Parameters__


	Integer last_sequence (Optional) -- The last sequence number seen

	[String] resolve (Optional) -- A list of references to resolve and embed in the response

__Returns__

	200 -- a list of records and sequence numbers



## [:POST] /update_monitor 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/update_monitor"

```

__Description__

Refresh the list of currently known edits

__Parameters__


	JSONModel(:active_edits) <request body> -- The list of active edits

__Returns__

	200 -- A list of records, the user editing it and the lock version for each



## [:POST] /users 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_admin":false,
"username":"username_21",
"name":"Name Number 608"}' \
  "http://localhost:8089/users?password=FMYBV&groups=127I603F972"

```

__Description__

Create a local user

__Parameters__


	String password -- The user's password

	[String] groups (Optional) -- Array of groups URIs to assign the user to

	JSONModel(:user) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}
	400 -- {:error => (description of error)}



## [:GET] /users 




  

```shell 
  
# return first 10 records    
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users?id_set=1,2,3,5,8"
# return an array of all the ids 
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users?all_ids=true"
  

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



## [:GET] /users/:id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users/1"
  

```

__Description__

Get a user's details (including their current permissions)

__Parameters__


	Integer id -- The username id to fetch

__Returns__

	200 -- (:user)



## [:POST] /users/:id 



  
  
    
      
        
      
    
  
  

  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_admin":false,
"username":"username_21",
"name":"Name Number 608"}' \
  "http://localhost:8089/users/1?password=TE787605U"

```

__Description__

Update a user's account

__Parameters__


	Integer id -- The ID of the record

	String password (Optional) -- The user's password

	JSONModel(:user) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:DELETE] /users/:id 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE "http://localhost:8089/users/1"

```

__Description__

Delete a user

__Parameters__


	Integer id -- The user to delete

__Returns__

	200 -- deleted



## [:POST] /users/:id/groups 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/users/1/groups?groups=116NOQJ&remove_groups=true"

```

__Description__

Update a user's groups

__Parameters__


	Integer id -- The ID of the record

	[String] groups (Optional) -- Array of groups URIs to assign the user to

	RESTHelpers::BooleanParam remove_groups -- Remove all groups from the user for the current repo_id if true

	Integer repo_id -- The Repository groups to clear

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}
	400 -- {:error => (description of error)}



## [:POST] /users/:username/become-user 




  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/users/1/become-user"

```

__Description__

Become a different user

__Parameters__


	Username username -- The username to become

__Returns__

	200 -- Accepted
	404 -- User not found



## [:POST] /users/:username/login 



  
  
    
      
        
      
    
  
    
      
        
      
    
  
  

  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/users/1/login?password=714482DH938&expiring=true"

```

__Description__

Log in

__Parameters__


	Username username -- Your username

	String password -- Your password

	RESTHelpers::BooleanParam expiring -- If true, the session will expire after 3600 seconds of inactivity.  If false, it will  expire after 604800 seconds of inactivity.

NOTE: Previously this parameter would cause the created session to last forever, but this generally isn't what you want.  The parameter name is unfortunate, but we're keeping it for backward-compatibility.

__Returns__

	200 -- Login accepted
	403 -- Login failed



## [:GET] /users/complete 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users/complete?query=E405AL23"
  

```

__Description__

Get a list of system users

__Parameters__


	String query -- A prefix to search for

__Returns__

	200 -- A list of usernames



## [:GET] /users/current-user 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/users/current-user"
  

```

__Description__

Get the currently logged in user

__Parameters__


__Returns__

	200 -- (:user)
	404 -- Not logged in



## [:GET] /version 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/version"
  

```

__Description__

Get the ArchivesSpace application version

__Parameters__


__Returns__

	200 -- ArchivesSpace (version)



## [:POST] /vocabularies 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/vocabularies"

```

__Description__

Create a Vocabulary

__Parameters__


	JSONModel(:vocabulary) <request body> -- The record to create

__Returns__

	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## [:GET] /vocabularies 



  
  
    
      
        
      
    
  
  

  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/vocabularies?ref_id=296851NI443"
  

```

__Description__

Get a list of Vocabularies

__Parameters__


	String ref_id (Optional) -- An alternate, externally-created ID for the vocabulary

__Returns__

	200 -- [(:vocabulary)]



## [:POST] /vocabularies/:id 




  
  

```shell 
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/vocabularies/1"

```

__Description__

Update a Vocabulary

__Parameters__


	Integer id -- The ID of the record

	JSONModel(:vocabulary) <request body> -- The updated record

__Returns__

	200 -- {:status => "Updated", :id => (id of updated object)}



## [:GET] /vocabularies/:id 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/vocabularies/1"
  

```

__Description__

Get a Vocabulary by ID

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- OK



## [:GET] /vocabularies/:id/terms 




  

```shell 
   
curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/vocabularies/1/terms"
  

```

__Description__

Get a list of Terms for a Vocabulary

__Parameters__


	Integer id -- The ID of the record

__Returns__

	200 -- [(:term)]




