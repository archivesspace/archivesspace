---


title: API Reference

language_tabs:
  - shell
  - python
toc_footers:
  - <a href='http://github.com/tripit/slate'>Documentation Powered by Slate</a>

includes:
  - errors

search: true
---

# Introduction

This is the documentation for the ArchivesSpace RESTful API. This documents the endpoints that are used by the backend server to edit records in the application.

Since not all backend/API end points require authentication, it is best to restrict access to port 8089 to only IP addresses you trust. Your firewall should be used to specify a range of IP addresses that are allowed to call your ArchivesSpace API endpoint. This is commonly called whitelisting or allowlisting.

This example API documentation page was created with [Slate](http://github.com/tripit/slate).

# Authentication

> Example Authentication Request:

```shell
# With shell, you can pass the correct header with each request
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
```

```python
# Using the ArchivesSnake library
from asnake.client import ASnakeClient

client = ASnakeClient(baseurl="http://localhost:8089",
                      username="admin",
                      password="admin")
client.authorize()
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

> It's a good idea to save the session key since this will be used for later requests:

```shell
# Mac/Unix terminal
export SESSION="9528190655b979f00817a5d38f9daf07d1686fed99a1d53dd2c9ff2d852a0c6e"

# Windows Command Prompt
set SESSION="9528190655b979f00817a5d38f9daf07d1686fed99a1d53dd2c9ff2d852a0c6e"

# Windows PowerShell
$env:SESSION="9528190655b979f00817a5d38f9daf07d1686fed99a1d53dd2c9ff2d852a0c6e"
```

```python
# Handled by ArchivesSnake library
# For more information, see:
# https://github.com/archivesspace-labs/ArchivesSnake/#low-level-api
```

Most requests to the ArchivesSpace backend require a user to be authenticated. Since not all requests to the backend require authentication it is important to restrict access to only trusted IP addresses.  Authentication can be done with a POST request to the /users/:user_name/login endpoint, with :user_name and :password parameters being supplied.

The JSON that is returned will have a session key, which can be stored and used for other requests. Sessions will expire after an hour, although you can change this in your config.rb file.

# Common Route Categories and Parameters

As you use the ArchivesSpace API, you may start to notice similarities between different endpoints, and arguments that repeatedly show up in URLs or parameter lists.  Some of the most general bear special description.

## Create/Read/Update/Destroy (CRUD) Endpoints

The simplest types of endpoints conceptually, these are endpoints that allow you to create new resources, fetch and update existing known resources, get all the resources of a particular type, and remove resources from the system.  Almost every kind of object in the system has routes of this type: here are the routes for `agent_corporate_entity` records.

Example routes:
- **Create:** [POST /agents/corporate_entities](#create-a-corporate-entity-agent)
- **Read (Index route):** [GET /agents/corporate_entities](#list-all-corporate-entity-agents)
- **Read (Single Record):** [GET /agents/corporate_entities/42](#get-a-corporate-entity-by-id)
- **Update:** [POST /agents/corporate_entities/42](#update-a-corporate-entity-agent)
- **Destroy:** [DELETE /agents/corporate_entities/42](#delete-a-corporate-entity-agent)

## Paginated Endpoints

Endpoints that represent groups of objects, rather than single objects, tend to be paginated.   Paginated endpoints are called out in the documentation as special, with some version of the following content appearing:

<aside class="notice">
  This endpoint is paginated. :page, :id_set, or :all_ids is required
  <ul>
    <li>Integer page &ndash; The page set to be returned</li>
    <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
    <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
    <li>Boolean all_ids &ndash; Return a list of all object ids</li>
  </ul>
</aside>

These endpoints support some or all of the following:

- paged access to objects (via :page)
- listing all matching ids (via :all_ids)
- fetching specific known objects via their database ids (via :id_set)


## Search routes

A number of routes in the ArchivesSpace API are designed to search for content across all or part of the records in the application.  These routes make use of [Solr](https://lucene.apache.org/solr/), a component bundled with ArchivesSpace and used to provide full text search over records.

The search routes present in the application as of this time are:

- [Search this archive](#search-this-archive)
- [Search across repositories](#search-across-repositories)
- [Search this repository](#search-this-repository)
- [Search across subjects](#search-across-subjects)
- [Search for top containers](#search-for-top-containers)
- [Search across location profiles](#search-across-location-profiles)

Search routes take quite a few different parameters, most of which correspond directly to Solr query parameters.  The most important parameter to understand is `q`, which is the query sent to Solr. This query is made in Lucene query syntax.  The relevant docs are located [here](https://lucene.apache.org/solr/guide/6_6/the-standard-query-parser.html#the-standard-query-parser).

To limit a search to records of a particular type or set of types, you can use the 'type' parameter.  This is only relevant for search endpoints that aren't limited to specific types.  Note that type is expected to be a *list* of types, even if there is only one type you care about.

```python
from asnake.client import ASnakeClient

client = ASnakeClient()
client.authorize()

# Search repository for records of any type with the word "pearlescent" in any field
client.get('repositories/2/search', params={'q': 'pearlescent', 'page': 1}).json()

# Search repository wth ID 24 for archival objects with "dragon" in their title field
client.get('repositories/2/search', params={'q': 'title:dragon', 'type': ['archival_object'], 'page': 1}).json()

```

### Notes on search routes and results

ArchivesSpace represents records as JSONModel Objects - this is what you get from and send to the system.

SOLR takes these records, and stores "documents" BASED ON these JSONModel objects in a searchable index.

Search routes query these documents, NOT the records themselves as stored in the database and represented by JSONModel.

JSONModel objects and SOLR documents are similar in some ways:

- both SOLR documents and JSONModel Objects are expressed in JSON
- in general, documents will always contain some subset of the JSONModel object they represent

But they also differ in quite a few important ways:

- SOLR documents don't necessarily have all fields from a JSONModel object
- SOLR documents do not automatically contain nested JSONModel Objects
- SOLR documents can have fields defined that are arbitrary "search representations" of fields in associated records, or combinations of fields in a record
- SOLR documents don't have a `jsonmodel_type` field - the `jsonmodel_type` of the record is stored as `primary_type` in SOLR

### How do I get the actual JSONModel from a search document?

In ArchivesSpace, SOLR documents all have a field `json`, which contains the JSONModel Object the document represents as a string.  You can use a JSON library to parse this string from the field, for example the json library in Python.

```python
import json
search_results = client.get('repositories/2/search', params={'q': 'title:dragon', 'type': ['archival_object']}).json()['results']

# get JSONModel from first search document in results
my_record = json.loads(search_results[0]['json'])
```

## refs and :resolve

```shell

curl -H "X-ArchivesSpace-Session: $SESSION" \
"http://localhost:8089/repositories/24/top_container?resolve[]=repository"

# JSON Output: Some keys have been left out in order to make the example shorter and clearer

{
  "lock_version": 11,
  "indicator": "1",
  "created_by": "admin",
  "last_modified_by": "admin",
  "type": "box",
  "jsonmodel_type": "top_container",
  "uri": "/repositories/24/top_containers/24470",
  "repository": {
    "ref": "/repositories/24",
    "_resolved": {
      "lock_version": 1,
      "repo_code": "HOU",
      "name": "Houghton Library",
      "org_code": "MH-H",
      "url": "http://nrs.harvard.edu/urn-3:hul.ois:HOU",
      "image_url": "http://nrs.harvard.edu/urn-3:HUL.OIS:fas_shield",
      "created_by": "admin",
      "last_modified_by": "admin",
      "publish": true,
      "jsonmodel_type": "repository",
      "uri": "/repositories/24",
      "display_string": "Houghton Library (HOU)",
      "agent_representation": {
        "ref": "/agents/corporate_entities/1511"
      }
    }
  },
  "restricted": false,
  "is_linked_to_published_record": true,
  "display_string": "Box 1: Series pfMS Am 21",
  "long_display_string": "MS Am 21, MS Am 21.5, MCZ 118, Series pfMS Am 21, Box 1"
}
```

```python
from asnake.client import ASnakeClient

client = ASnakeClient()
client.authorize()

client.get('repositories/24/top_container', params={'resolve': ['repository']}).json()

# JSON Output: Some keys have been left out in order to make the example shorter.

{
  "lock_version": 11,
  "indicator": "1",
  "created_by": "admin",
  "last_modified_by": "admin",
  "type": "box",
  "jsonmodel_type": "top_container",
  "uri": "/repositories/24/top_containers/24470",
  "repository": {
    "ref": "/repositories/24",
    "_resolved": {
      "lock_version": 1,
      "repo_code": "HOU",
      "name": "Houghton Library",
      "org_code": "MH-H",
      "url": "http://nrs.harvard.edu/urn-3:hul.ois:HOU",
      "image_url": "http://nrs.harvard.edu/urn-3:HUL.OIS:fas_shield",
      "created_by": "admin",
      "last_modified_by": "admin",
      "publish": True,
      "jsonmodel_type": "repository",
      "uri": "/repositories/24",
      "display_string": "Houghton Library (HOU)",
      "agent_representation": {"ref": "/agents/corporate_entities/1511"}}},
  "restricted": False,
  "is_linked_to_published_record": True,
  "display_string": "Box 1: Series pfMS Am 21",
  "long_display_string": "MS Am 21, MS Am 21.5, MCZ 118, Series pfMS Am 21, Box 1"
}
```


In ArchivesSpace's JSONModel schema, a `ref` is a link to another object.  They take the general form of a JSON object with a `ref` key, containing the URI of an object in ArchivesSpace, and optionally other attributes. For example, a ref to a `resource` might look like this:

<code>
{'ref': '/repositories/13/resources/155'}
</code>

The :resolve parameter is a way to tell ArchivesSpace to attach the full object to these refs; it is passed in as an array of keys to "prefetch" in the returned JSON.  The object is included in the ref under a `_resolved` key.

# ArchivesSpace REST API
As of 2021-09-21 14:08:49 -0400 the following REST endpoints exist in the master branch of the development repository:


## Create a corporate entity agent



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number":"37234 6300 054",
"ext":"E953C566558"}],
"notes":[{ "jsonmodel_type":"note_contact_note",
"date_of_contact":"TY918852M",
"contact_notes":"TTM483M"}],
"is_representative":false,
"name":"Name Number 6",
"address_1":"C386HET",
"address_3":"NPU409W",
"city":"BI351496828",
"region":"F94501NR",
"fax":"EKE354J",
"email_signature":"YSEXM"}],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"conference_meeting":false,
"jurisdiction":false,
"parallel_names":[],
"rules":"aacr",
"primary_name":"Name Number 5",
"subordinate_name_1":"7968494U545",
"subordinate_name_2":"QXX604O",
"number":"V441C455I",
"sort_name":"SORT v - 4",
"qualifier":"BHK735T",
"dates":"C140KVG",
"authority_id":"http://www.example-8-1632179081.com",
"source":"nad"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089/agents/corporate_entities"

```



__Endpoint__

```[:POST] /agents/corporate_entities ```


__Description__

Create a corporate entity agent.

  
  


__Accepts Payload of Type__

JSONModel(:agent_corporate_entity)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## List all corporate entity agents




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/corporate_entities?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/corporate_entities?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/corporate_entities?all_ids=true"

```



__Endpoint__

```[:GET] /agents/corporate_entities ```


__Description__

List all corporate entity agents.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>




__Returns__

  	200 -- [(:agent_corporate_entity)]



## Update a corporate entity agent



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number":"37234 6300 054",
"ext":"E953C566558"}],
"notes":[{ "jsonmodel_type":"note_contact_note",
"date_of_contact":"TY918852M",
"contact_notes":"TTM483M"}],
"is_representative":false,
"name":"Name Number 6",
"address_1":"C386HET",
"address_3":"NPU409W",
"city":"BI351496828",
"region":"F94501NR",
"fax":"EKE354J",
"email_signature":"YSEXM"}],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"conference_meeting":false,
"jurisdiction":false,
"parallel_names":[],
"rules":"aacr",
"primary_name":"Name Number 5",
"subordinate_name_1":"7968494U545",
"subordinate_name_2":"QXX604O",
"number":"V441C455I",
"sort_name":"SORT v - 4",
"qualifier":"BHK735T",
"dates":"C140KVG",
"authority_id":"http://www.example-8-1632179081.com",
"source":"nad"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089/agents/corporate_entities/1"

```



__Endpoint__

```[:POST] /agents/corporate_entities/:id ```


__Description__

Update a corporate entity agent.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:agent_corporate_entity)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get a corporate entity by ID



  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/corporate_entities/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /agents/corporate_entities/:id ```


__Description__

Get a corporate entity by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            ID of the corporate entity agent
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent_corporate_entity)

  	404 -- Not found



## Delete a corporate entity agent



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/agents/corporate_entities/1"

```



__Endpoint__

```[:DELETE] /agents/corporate_entities/:id ```


__Description__

Delete a corporate entity agent.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            ID of the corporate entity agent
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Publish a corporate entity agent and all its sub-records



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/agents/corporate_entities/1/publish"

```



__Endpoint__

```[:POST] /agents/corporate_entities/:id/publish ```


__Description__

Publish a corporate entity agent and all its sub-records.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Create a family agent



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_family",
"agent_contacts":[],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"parallel_names":[],
"rules":"aacr",
"family_name":"Name Number 3",
"sort_name":"SORT j - 2",
"dates":"866654628PU",
"qualifier":"SNCOB",
"prefix":"V327753799131",
"authority_id":"http://www.example-4-1632179079.com",
"source":"ingest"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089/agents/families"

```



__Endpoint__

```[:POST] /agents/families ```


__Description__

Create a family agent.

  
  


__Accepts Payload of Type__

JSONModel(:agent_family)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## List all family agents




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/families?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/families?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/families?all_ids=true"

```



__Endpoint__

```[:GET] /agents/families ```


__Description__

List all family agents.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>




__Returns__

  	200 -- [(:agent_family)]



## Update a family agent



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_family",
"agent_contacts":[],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"parallel_names":[],
"rules":"aacr",
"family_name":"Name Number 3",
"sort_name":"SORT j - 2",
"dates":"866654628PU",
"qualifier":"SNCOB",
"prefix":"V327753799131",
"authority_id":"http://www.example-4-1632179079.com",
"source":"ingest"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089/agents/families/1"

```



__Endpoint__

```[:POST] /agents/families/:id ```


__Description__

Update a family agent.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:agent_family)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get a family by ID



  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/families/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /agents/families/:id ```


__Description__

Get a family by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            ID of the family agent
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)

  	404 -- Not found



## Delete an agent family



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/agents/families/1"

```



__Endpoint__

```[:DELETE] /agents/families/:id ```


__Description__

Delete an agent family.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            ID of the family agent
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Publish a family agent and all its sub-records



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/agents/families/1/publish"

```



__Endpoint__

```[:POST] /agents/families/:id/publish ```


__Description__

Publish a family agent and all its sub-records.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Create a person agent



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_person",
"agent_contacts":[],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"parallel_names":[],
"rules":"aacr",
"source":"naf",
"primary_name":"Name Number 14",
"sort_name":"SORT m - 10",
"name_order":"direct",
"number":"25214C963586",
"dates":"306TWVY",
"qualifier":"Y62VFF",
"fuller_form":"OETNM",
"prefix":"325LCW206",
"title":"193294WA536",
"suffix":"LOK423R",
"rest_of_name":"TJDCW",
"authority_id":"http://www.example-25-1632179086.com"}],
"agent_genders":[],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089/agents/people"

```



__Endpoint__

```[:POST] /agents/people ```


__Description__

Create a person agent.

  
  


__Accepts Payload of Type__

JSONModel(:agent_person)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## List all person agents




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/people?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/people?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/people?all_ids=true"

```



__Endpoint__

```[:GET] /agents/people ```


__Description__

List all person agents.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>




__Returns__

  	200 -- [(:agent_person)]



## Update a person agent



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_person",
"agent_contacts":[],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"parallel_names":[],
"rules":"aacr",
"source":"naf",
"primary_name":"Name Number 14",
"sort_name":"SORT m - 10",
"name_order":"direct",
"number":"25214C963586",
"dates":"306TWVY",
"qualifier":"Y62VFF",
"fuller_form":"OETNM",
"prefix":"325LCW206",
"title":"193294WA536",
"suffix":"LOK423R",
"rest_of_name":"TJDCW",
"authority_id":"http://www.example-25-1632179086.com"}],
"agent_genders":[],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089/agents/people/1"

```



__Endpoint__

```[:POST] /agents/people/:id ```


__Description__

Update a person agent.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:agent_person)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get a person by ID



  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/people/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /agents/people/:id ```


__Description__

Get a person by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            ID of the person agent
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)

  	404 -- Not found



## Delete an agent person



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/agents/people/1"

```



__Endpoint__

```[:DELETE] /agents/people/:id ```


__Description__

Delete an agent person.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            ID of the person agent
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Publish an agent person and all its sub-records



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/agents/people/1/publish"

```



__Endpoint__

```[:POST] /agents/people/:id/publish ```


__Description__

Publish an agent person and all its sub-records.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Create a software agent



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_software",
"agent_contacts":[],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"parallel_names":[],
"rules":"dacs",
"source":"snac",
"software_name":"Name Number 12",
"sort_name":"SORT k - 9",
"qualifier":"TRO425606",
"dates":"KHBP456",
"authority_id":"http://www.example-24-1632179086.com"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089/agents/software"

```



__Endpoint__

```[:POST] /agents/software ```


__Description__

Create a software agent.

  
  


__Accepts Payload of Type__

JSONModel(:agent_software)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## List all software agents




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/software?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/software?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/software?all_ids=true"

```



__Endpoint__

```[:GET] /agents/software ```


__Description__

List all software agents.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>




__Returns__

  	200 -- [(:agent_software)]



## Update a software agent



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_software",
"agent_contacts":[],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"parallel_names":[],
"rules":"dacs",
"source":"snac",
"software_name":"Name Number 12",
"sort_name":"SORT k - 9",
"qualifier":"TRO425606",
"dates":"KHBP456",
"authority_id":"http://www.example-24-1632179086.com"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089/agents/software/1"

```



__Endpoint__

```[:POST] /agents/software/:id ```


__Description__

Update a software agent.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:agent_software)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get a software agent by ID



  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/agents/software/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /agents/software/:id ```


__Description__

Get a software agent by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            ID of the software agent
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)

  	404 -- Not found



## Delete a software agent



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/agents/software/1"

```



__Endpoint__

```[:DELETE] /agents/software/:id ```


__Description__

Delete a software agent.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            ID of the software agent
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Publish a software agent and all its sub-records



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/agents/software/1/publish"

```



__Endpoint__

```[:POST] /agents/software/:id/publish ```


__Description__

Publish a software agent and all its sub-records.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Redirect to resource identified by ARK Name



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/ark*/1/1"

```



__Endpoint__

```[:GET] /ark*/:naan/:id ```


__Description__

Redirect to resource identified by ARK Name.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	404 -- Not found

  	302 -- redirect



## Carry out delete requests against a list of records



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/batch_delete?record_uris=Y528728UT"

```



__Endpoint__

```[:POST] /batch_delete ```


__Description__

Carry out delete requests against a list of records.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>record_uris</code></td>
        <td style="word-break: break-word;">
            A list of record uris
            
        </td>
        <td>[String]</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## List records by their external ID(s)



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/by-external-id?eid=I99672GU&type=D66246E881"

```



__Endpoint__

```[:GET] /by-external-id ```


__Description__

List records by their external ID(s).

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>eid</code></td>
        <td style="word-break: break-word;">
            An external ID to find
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>type</code></td>
        <td style="word-break: break-word;">
            The record type to search (useful if IDs may be shared between different types)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	303 -- A redirect to the URI named by the external ID (if there's only one)

  	300 -- A JSON-formatted list of URIs if there were multiple matches

  	404 -- No external ID matched



## Get an Enumeration Value



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/config/enumeration_values/1"

```



__Endpoint__

```[:GET] /config/enumeration_values/:enum_val_id ```


__Description__

Get an Enumeration Value.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>enum_val_id</code></td>
        <td style="word-break: break-word;">
            The ID of the enumeration value to retrieve
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:enumeration_value)



## Update an enumeration value



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/config/enumeration_values/1"

```



__Endpoint__

```[:POST] /config/enumeration_values/:enum_val_id ```


__Description__

Update an enumeration value.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>enum_val_id</code></td>
        <td style="word-break: break-word;">
            The ID of the enumeration value to update
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:enumeration_value)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Update the position of an ennumeration value



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/config/enumeration_values/1/position?position=1"

```



__Endpoint__

```[:POST] /config/enumeration_values/:enum_val_id/position ```


__Description__

Update the position of an ennumeration value.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>enum_val_id</code></td>
        <td style="word-break: break-word;">
            The ID of the enumeration value to update
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The target position in the value list
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Suppress this value



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/config/enumeration_values/1/suppressed?suppressed=true"

```



__Endpoint__

```[:POST] /config/enumeration_values/:enum_val_id/suppressed ```


__Description__

Suppress this value.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>enum_val_id</code></td>
        <td style="word-break: break-word;">
            The ID of the enumeration value to update
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>suppressed</code></td>
        <td style="word-break: break-word;">
            Suppression state
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}

  	400 -- {:error => (description of error)}



## List all defined enumerations




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/config/enumerations"

```



__Endpoint__

```[:GET] /config/enumerations ```


__Description__

List all defined enumerations.




__Returns__

  	200 -- [(:enumeration)]



## Create an enumeration



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/config/enumerations"

```



__Endpoint__

```[:POST] /config/enumerations ```


__Description__

Create an enumeration.

  
  


__Accepts Payload of Type__

JSONModel(:enumeration)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Update an enumeration



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/config/enumerations/1"

```



__Endpoint__

```[:POST] /config/enumerations/:enum_id ```


__Description__

Update an enumeration.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>enum_id</code></td>
        <td style="word-break: break-word;">
            The ID of the enumeration to update
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:enumeration)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get an Enumeration



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/config/enumerations/1"

```



__Endpoint__

```[:GET] /config/enumerations/:enum_id ```


__Description__

Get an Enumeration.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>enum_id</code></td>
        <td style="word-break: break-word;">
            The ID of the enumeration to retrieve
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:enumeration)



## List all defined enumerations as a csv




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/config/enumerations/csv"

```



__Endpoint__

```[:GET] /config/enumerations/csv ```


__Description__

List all defined enumerations as a csv.




__Returns__

  	200 -- (csv)



## Migrate all records from one value to another



  
    
  

  
    
  
  
  
  ```shell
curl -H 'Content-Type: application/json' \
    -H "X-ArchivesSpace-Session: $SESSION" \
    -d '{"enum_uri": "/config/enumerations/17", "from": "sir", "to": "mr"}' \
    "http://localhost:8089/config/enumerations/migration"

```


```python
from asnake.client import ASnakeClient

client = ASnakeClient()
client.authorize()

client.post('/config/enumerations/migration',
            json={
                'enum_uri': '/config/enumerations/17',
                'from': 'sir', #value to be deleted
                'to': 'mr' #value to merge into
                }
            )

```


__Endpoint__

```[:POST] /config/enumerations/migration ```


__Description__

Migrate all records from one value to another.

  
  


__Accepts Payload of Type__

JSONModel(:enumeration_migration)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}

  	404 -- Not found



## Get an Enumeration by Name



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/config/enumerations/names/1"

```



__Endpoint__

```[:GET] /config/enumerations/names/:enum_name ```


__Description__

Get an Enumeration by Name.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>enum_name</code></td>
        <td style="word-break: break-word;">
            The name of the enumeration to retrieve
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:enumeration)



## Create a Container_Profile



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"GNY733C",
"url":"Q182UQK",
"dimension_units":"inches",
"extent_dimension":"width",
"depth":"70",
"height":"37",
"width":"46"}' \
  "http://localhost:8089/container_profiles"

```



__Endpoint__

```[:POST] /container_profiles ```


__Description__

Create a Container_Profile.

  
  


__Accepts Payload of Type__

JSONModel(:container_profile)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## Get a list of Container Profiles




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/container_profiles?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/container_profiles?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/container_profiles?all_ids=true"

```



__Endpoint__

```[:GET] /container_profiles ```


__Description__

Get a list of Container Profiles.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>




__Returns__

  	200 -- [(:container_profile)]



## Update a Container Profile



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"GNY733C",
"url":"Q182UQK",
"dimension_units":"inches",
"extent_dimension":"width",
"depth":"70",
"height":"37",
"width":"46"}' \
  "http://localhost:8089/container_profiles/1"

```



__Endpoint__

```[:POST] /container_profiles/:id ```


__Description__

Update a Container Profile.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:container_profile)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a Container Profile by ID



  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/container_profiles/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /container_profiles/:id ```


__Description__

Get a Container Profile by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:container_profile)



## Delete an Container Profile



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/container_profiles/1"

```



__Endpoint__

```[:DELETE] /container_profiles/:id ```


__Description__

Delete an Container Profile.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Get the global Preferences records for the current user.




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/current_global_preferences"

```



__Endpoint__

```[:GET] /current_global_preferences ```


__Description__

Get the global Preferences records for the current user..




__Returns__

  	200 -- {(:preference)}



## Calculate the dates of an archival object tree



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/date_calculator?record_uri=T229BF39&label=WV17C702"

```



__Endpoint__

```[:GET] /date_calculator ```


__Description__

Calculate the dates of an archival object tree.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>record_uri</code></td>
        <td style="word-break: break-word;">
            The uri of the object
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>label</code></td>
        <td style="word-break: break-word;">
            The date label to filter on
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Calculation results



## Get a stream of deleted records




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/delete-feed?page=1&page_size=10"

```



__Endpoint__

```[:GET] /delete-feed ```


__Description__

Get a stream of deleted records.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
</ul>
</aside>



__Returns__

  	200 -- a list of URIs that were deleted



## Calculate the extent of an archival object tree



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/extent_calculator?record_uri=TBIUC&unit=233568MEK"

```



__Endpoint__

```[:GET] /extent_calculator ```


__Description__

Calculate the extent of an archival object tree.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>record_uri</code></td>
        <td style="word-break: break-word;">
            The uri of the object
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>unit</code></td>
        <td style="word-break: break-word;">
            The unit of measurement to use
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Calculation results



## List all supported job types




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/job_types"

```



__Endpoint__

```[:GET] /job_types ```


__Description__

List all supported job types.




__Returns__

  	200 -- A list of supported job types



## Create a Location_Profile



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"ELLIM",
"dimension_units":"millimeters",
"depth":"88",
"height":"59",
"width":"10"}' \
  "http://localhost:8089/location_profiles"

```



__Endpoint__

```[:POST] /location_profiles ```


__Description__

Create a Location_Profile.

  
  


__Accepts Payload of Type__

JSONModel(:location_profile)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## Get a list of Location Profiles




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/location_profiles?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/location_profiles?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/location_profiles?all_ids=true"

```



__Endpoint__

```[:GET] /location_profiles ```


__Description__

Get a list of Location Profiles.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>




__Returns__

  	200 -- [(:location_profile)]



## Update a Location Profile



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"ELLIM",
"dimension_units":"millimeters",
"depth":"88",
"height":"59",
"width":"10"}' \
  "http://localhost:8089/location_profiles/1"

```



__Endpoint__

```[:POST] /location_profiles/:id ```


__Description__

Update a Location Profile.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:location_profile)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a Location Profile by ID



  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/location_profiles/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /location_profiles/:id ```


__Description__

Get a Location Profile by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:location_profile)



## Delete an Location Profile



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/location_profiles/1"

```



__Endpoint__

```[:DELETE] /location_profiles/:id ```


__Description__

Delete an Location Profile.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Create a Location



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location",
"external_ids":[],
"functions":[],
"building":"36 E 5th Street",
"floor":"9",
"room":"2",
"area":"Back",
"barcode":"10000110011110101100",
"temporary":"conservation"}' \
  "http://localhost:8089/locations"

```



__Endpoint__

```[:POST] /locations ```


__Description__

Create a Location.

  
  


__Accepts Payload of Type__

JSONModel(:location)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## Get a list of locations




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/locations?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/locations?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/locations?all_ids=true"

```



__Endpoint__

```[:GET] /locations ```


__Description__

Get a list of locations.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>




__Returns__

  	200 -- [(:location)]



## Update a Location



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location",
"external_ids":[],
"functions":[],
"building":"36 E 5th Street",
"floor":"9",
"room":"2",
"area":"Back",
"barcode":"10000110011110101100",
"temporary":"conservation"}' \
  "http://localhost:8089/locations/1"

```



__Endpoint__

```[:POST] /locations/:id ```


__Description__

Update a Location.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:location)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a Location by ID



  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/locations/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /locations/:id ```


__Description__

Get a Location by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:location)



## Delete a Location



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/locations/1"

```



__Endpoint__

```[:DELETE] /locations/:id ```


__Description__

Delete a Location.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Create a Batch of Locations



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/locations/batch?dry_run=true"

```



__Endpoint__

```[:POST] /locations/batch ```


__Description__

Create a Batch of Locations.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>dry_run</code></td>
        <td style="word-break: break-word;">
            If true, don't create the locations, just list them
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:location_batch)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Update a Location



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/locations/batch_update"

```



__Endpoint__

```[:POST] /locations/batch_update ```


__Description__

Update a Location.

  
  


__Accepts Payload of Type__

JSONModel(:location_batch_update)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Log out the current session




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/logout"

```



__Endpoint__

```[:POST] /logout ```


__Description__

Log out the current session.




__Returns__

  	200 -- Session logged out



## Carry out a merge request against Agent records



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/merge_requests/agent"

```



__Endpoint__

```[:POST] /merge_requests/agent ```


__Description__

Carry out a merge request against Agent records.

  
  


__Accepts Payload of Type__

JSONModel(:merge_request)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Carry out a detailed merge request against Agent records



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
  
  ```shell
curl -H 'Content-Type: application/json' \
    -H "X-ArchivesSpace-Session: $SESSION" \
    -d '{"dry_run":true, \
         "merge_request_detail":{ \
           "jsonmodel_type":"merge_request_detail", \
           "victims":[{"ref":"/agents/people/3"}], \
           "target":{"ref":"/agents/people/4"}, \
           "selections":{
             "names":[{"primary_name":"REPLACE", "position":"0"}], \
             "agent_record_identifiers":[{"append":"APPEND", "position":"0"}], \
             "agent_conventions_declarations":[
               {"append":"REPLACE", "position":"1"}, \
               {"append":"REPLACE", "position":"0"} \
              ],
           } \
        } \
      } \
    "http://localhost:8089/merge_requests/agent_detail"

```




__Endpoint__

```[:POST] /merge_requests/agent_detail ```


__Description__

Carry out a detailed merge request against Agent records.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>dry_run</code></td>
        <td style="word-break: break-word;">
            If true, don't process the merge, just display the merged record
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:merge_request_detail)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Carry out a merge request against Container Profile records



  
    
  

  
    
  
  
  
  ```shell
curl -H 'Content-Type: application/json' \
    -H "X-ArchivesSpace-Session: $SESSION" \
    -d '{"uri": "merge_requests/container_profile", "target": {"ref": "/container_profiles/1" },"victims": [{"ref": "/container_profiles/2"}]}' \
    "http://localhost:8089/merge_requests/container_profile"

```


```python
from asnake.client import ASnakeClient
client = ASnakeClient()
client.authorize()
client.post('/merge_requests/container_profile',
        json={
            'uri': 'merge_requests/container_profile',
            'target': {
                'ref': '/container_profiles/1'
              },
            'victims': [
                {
                    'ref': '/container_profiles/2'
                }
              ]
            }
      )

```


__Endpoint__

```[:POST] /merge_requests/container_profile ```


__Description__

Carry out a merge request against Container Profile records.

  
  


__Accepts Payload of Type__

JSONModel(:merge_request)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Carry out a merge request against Digital_Object records



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/merge_requests/digital_object"

```



__Endpoint__

```[:POST] /merge_requests/digital_object ```


__Description__

Carry out a merge request against Digital_Object records.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:merge_request)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Carry out a merge request against Resource records



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/merge_requests/resource"

```



__Endpoint__

```[:POST] /merge_requests/resource ```


__Description__

Carry out a merge request against Resource records.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:merge_request)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Carry out a merge request against Subject records



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/merge_requests/subject"

```



__Endpoint__

```[:POST] /merge_requests/subject ```


__Description__

Carry out a merge request against Subject records.

  
  


__Accepts Payload of Type__

JSONModel(:merge_request)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Carry out a merge request against Top Container records



  
    
  
  
    
  

  
    
  
  
    
  
  
  
  ```shell
curl -H 'Content-Type: application/json' \
    -H "X-ArchivesSpace-Session: $SESSION" \
    -d '{"uri": "merge_requests/top_container", "target": {"ref": "/repositories/2/top_containers/1" },"victims": [{"ref": "/repositories/2/top_containers/2"}]}' \
    "http://localhost:8089/merge_requests/top_container?repo_id=2"

```


```python
from asnake.client import ASnakeClient
client = ASnakeClient()
client.authorize()
client.post('/merge_requests/top_container?repo_id=2',
        json={
            'uri': 'merge_requests/top_container',
            'target': {
                'ref': '/repositories/2/top_containers/80'
              },
            'victims': [
                {
                    'ref': '/repositories/2/top_containers/171'
                }
              ]
            }
      )

```


__Endpoint__

```[:POST] /merge_requests/top_container ```


__Description__

Carry out a merge request against Top Container records.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:merge_request)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a stream of notifications



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/notifications?last_sequence=1"

```



__Endpoint__

```[:GET] /notifications ```


__Description__

Get a stream of notifications.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>last_sequence</code></td>
        <td style="word-break: break-word;">
            The last sequence number seen
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- a list of notifications



## Get a list of Permissions



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/permissions?level=LGJCG"

```



__Endpoint__

```[:GET] /permissions ```


__Description__

Get a list of Permissions.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>level</code></td>
        <td style="word-break: break-word;">
            The permission level to get (one of: repository, global, all)
            
            <br>
            <b>Note: </b> Must be one of repository, global, all
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:permission)]



## List all reports




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/reports"

```



__Endpoint__

```[:GET] /reports ```


__Description__

List all reports.




__Returns__

  	200 -- report list in json



## Get a list of availiable options for custom reports




  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/reports/custom_data"

```




__Endpoint__

```[:GET] /reports/custom_data ```


__Description__

Get a list of availiable options for custom reports.




__Returns__

  	200 -- 

  	h -- a



## Get a static asset for a report



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/reports/static/*?splat=ER911YQ"

```



__Endpoint__

```[:GET] /reports/static/* ```


__Description__

Get a static asset for a report.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>splat</code></td>
        <td style="word-break: break-word;">
            The requested asset
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- the asset



## Create a Repository



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"repository",
"name":"Description: 2",
"is_slug_auto":true,
"repo_code":"ASPACE REPO 2 -- 119175",
"org_code":"IQNTA",
"image_url":"http://www.example-2-1632179079.com",
"url":"http://www.example-3-1632179079.com",
"country":"US"}' \
  "http://localhost:8089/repositories"

```



__Endpoint__

```[:POST] /repositories ```


__Description__

Create a Repository.

  
  


__Accepts Payload of Type__

JSONModel(:repository)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	403 -- access_denied



## Get a list of Repositories



  
    
  
  
  
    
      
    
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories ```


__Description__

Get a list of Repositories.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:repository)]



## Update a repository



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"repository",
"name":"Description: 2",
"is_slug_auto":true,
"repo_code":"ASPACE REPO 2 -- 119175",
"org_code":"IQNTA",
"image_url":"http://www.example-2-1632179079.com",
"url":"http://www.example-3-1632179079.com",
"country":"US"}' \
  "http://localhost:8089/repositories/1"

```



__Endpoint__

```[:POST] /repositories/:id ```


__Description__

Update a repository.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:repository)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a Repository by ID



  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:id ```


__Description__

Get a Repository by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:repository)

  	404 -- Not found



## Delete a Repository



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id ```


__Description__

Delete a Repository.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Create an Accession



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"accession",
"external_ids":[],
"is_slug_auto":true,
"related_accessions":[],
"accession_date":"2008-10-27",
"classifications":[],
"subjects":[],
"linked_events":[],
"extents":[],
"lang_materials":[],
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
"metadata_rights_declarations":[],
"id_0":"825292U360R",
"id_1":"201828N940I",
"id_2":"P28SRK",
"id_3":"225WRIG",
"title":"Accession Title: 10",
"content_description":"Description: 10",
"condition_description":"Description: 11"}' \
  "http://localhost:8089/repositories/2/accessions"

```



__Endpoint__

```[:POST] /repositories/:repo_id/accessions ```


__Description__

Create an Accession.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:accession)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## Get a list of Accessions for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/accessions?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/accessions?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/accessions?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/accessions ```


__Description__

Get a list of Accessions for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:accession)]



## Update an Accession



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"accession",
"external_ids":[],
"is_slug_auto":true,
"related_accessions":[],
"accession_date":"2008-10-27",
"classifications":[],
"subjects":[],
"linked_events":[],
"extents":[],
"lang_materials":[],
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
"metadata_rights_declarations":[],
"id_0":"825292U360R",
"id_1":"201828N940I",
"id_2":"P28SRK",
"id_3":"225WRIG",
"title":"Accession Title: 10",
"content_description":"Description: 10",
"condition_description":"Description: 11"}' \
  "http://localhost:8089/repositories/2/accessions/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/accessions/:id ```


__Description__

Update an Accession.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:accession)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get an Accession by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/accessions/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/accessions/:id ```


__Description__

Get an Accession by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:accession)



## Delete an Accession



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/accessions/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/accessions/:id ```


__Description__

Delete an Accession.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Suppress this record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/accessions/1/suppressed?suppressed=true"

```



__Endpoint__

```[:POST] /repositories/:repo_id/accessions/:id/suppressed ```


__Description__

Suppress this record.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>suppressed</code></td>
        <td style="word-break: break-word;">
            Suppression state
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## Get Top Containers linked to an Accession



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/accessions/1/top_containers?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/accessions/:id/top_containers ```


__Description__

Get Top Containers linked to an Accession.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- a list of linked top containers

  	404 -- Not found



## Transfer this record to a different repository



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/accessions/1/transfer?target_repo=209XW199J"

```



__Endpoint__

```[:POST] /repositories/:repo_id/accessions/:id/transfer ```


__Description__

Transfer this record to a different repository.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>target_repo</code></td>
        <td style="word-break: break-word;">
            The URI of the target repository
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- moved



## Get metadata for an MARC Auth export of a corporate entity



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/agents/corporate_entities/marc21/1.:fmt/metadata"

```



__Endpoint__

```[:GET] /repositories/:repo_id/agents/corporate_entities/marc21/:id.:fmt/metadata ```


__Description__

Get metadata for an MARC Auth export of a corporate entity.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get a MARC Auth representation of a Corporate Entity



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/agents/corporate_entities/marc21/1.xml"

```



__Endpoint__

```[:GET] /repositories/:repo_id/agents/corporate_entities/marc21/:id.xml ```


__Description__

Get a MARC Auth representation of a Corporate Entity.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)



## Get metadata for an MARC Auth export of a family



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/agents/families/marc21/1.:fmt/metadata"

```



__Endpoint__

```[:GET] /repositories/:repo_id/agents/families/marc21/:id.:fmt/metadata ```


__Description__

Get metadata for an MARC Auth export of a family.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get an MARC Auth representation of a Family



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/agents/families/marc21/1.xml"

```



__Endpoint__

```[:GET] /repositories/:repo_id/agents/families/marc21/:id.xml ```


__Description__

Get an MARC Auth representation of a Family.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)



## Get metadata for an MARC Auth export of a person



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/agents/people/marc21/1.:fmt/metadata"

```



__Endpoint__

```[:GET] /repositories/:repo_id/agents/people/marc21/:id.:fmt/metadata ```


__Description__

Get metadata for an MARC Auth export of a person.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get an MARC Auth representation of an Person



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/agents/people/marc21/1.xml"

```



__Endpoint__

```[:GET] /repositories/:repo_id/agents/people/marc21/:id.xml ```


__Description__

Get an MARC Auth representation of an Person.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)



## Get metadata for an EAC-CPF export of a corporate entity



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/archival_contexts/corporate_entities/1238.:fmt/metadata"

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

eac_cpf_corp_fmt = client.get("/repositories/2/archival_contexts/corporate_entities/1238.:fmt/metadata")
# replace 2 for your repository ID and 1238 with your corporate agent ID. Find these at the URI on the staff interface

print(eac_cpf_corp_fmt.content)
# Sample output: {"filename":"title_20210218_182435_UTC__eac.xml","mimetype":"application/xml"}

# For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_corp_fmt.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata ```


__Description__

Get metadata for an EAC-CPF export of a corporate entity.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get an EAC-CPF representation of a Corporate Entity



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/archival_contexts/corporate_entities/1238.xml" --output eac_cpf_corp.xml

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

eac_cpf_corp_xml = client.get("/repositories/2/archival_contexts/corporate_entities/1238.xml")
# replace 2 for your repository ID and 1238 with your corporate agent ID. Find these at the URI on the staff interface

with open("eac_cpf_corp.xml", "wb") as file:  # save the file
    file.write(eac_cpf_corp_xml.content)  # write the file content to our file.
    file.close()

# For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_corp_xml.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/corporate_entities/:id.xml ```


__Description__

Get an EAC-CPF representation of a Corporate Entity.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)



## Get metadata for an EAC-CPF export of a family



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/archival_contexts/families/479.:fmt/metadata" --output eac_cpf_fam.fmt

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

eac_cpf_fam_fmt = client.get("/repositories/2/archival_contexts/families/479.:fmt/metadata")
# replace 2 for your repository ID and 479 with your family agent ID. Find these at the URI on the staff interface

print(eac_cpf_fam_fmt.content)
# Sample output: {"filename":"Adams_family_20210218_182435_UTC__eac.xml","mimetype":"application/xml"}

# For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_fam_fmt.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata ```


__Description__

Get metadata for an EAC-CPF export of a family.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get an EAC-CPF representation of a Family



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/archival_contexts/families/479.xml" --output eac_cpf_fam.xml

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

eac_cpf_fam_xml = client.get("/repositories/2/archival_contexts/families/479.xml")
# replace 2 for your repository ID and 479 with your family agent ID. Find these at the URI on the staff interface

with open("eac_cpf_fam.xml", "wb") as file:  # save the file
    file.write(eac_cpf_fam_xml.content)  # write the file content to our file.
    file.close()

# For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_fam_xml.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/families/:id.xml ```


__Description__

Get an EAC-CPF representation of a Family.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)



## Get metadata for an EAC-CPF export of a person



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/archival_contexts/people/159.:fmt/metadata"

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

eac_cpf_fmt = client.get("/repositories/2/archival_contexts/people/159.:fmt/metadata")
# replace 2 for your repository ID and 159 with your agent ID. Find these at the URI on the staff interface

print(eac_cpf_fmt.content)
# Sample output: {"filename":"title_20210218_182435_UTC__eac.xml","mimetype":"application/xml"}

# For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_fmt.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata ```


__Description__

Get metadata for an EAC-CPF export of a person.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get an EAC-CPF representation of an Agent



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/archival_contexts/people/159.xml" --output eac_cpf.xml

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

eac_cpf_xml = client.get("/repositories/2/archival_contexts/people/159.xml")
# replace 2 for your repository ID and 159 with your agent ID. Find these at the URI on the staff interface

with open("eac_cpf.xml", "wb") as file:  # save the file
    file.write(eac_cpf_xml.content)  # write the file content to our file.
    file.close()

# For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_xml.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/people/:id.xml ```


__Description__

Get an EAC-CPF representation of an Agent.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)



## Get metadata for an EAC-CPF export of a software



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/archival_contexts/softwares/1.:fmt/metadata"

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

eac_cpf_soft_fmt = client.get("/repositories/2/archival_contexts/softwares/1.:fmt/metadata")
# replace 2 for your repository ID and 1 with your software agent ID. Find these at the URI on the staff interface

print(eac_cpf_soft_fmt.content)
# Sample output: {"filename":"ArchivesSpace_20210218_182253_UTC__eac.xml","mimetype":"application/xml"}

# For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_soft_fmt.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/softwares/:id.:fmt/metadata ```

<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Software agents cannot be validly mapped to an EAC record, thus exporting is no longer supported.</p>
  
</aside>

__Description__

Get metadata for an EAC-CPF export of a software.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get an EAC-CPF representation of a Software agent



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/archival_contexts/softwares/1.xml" --output eac_cpf_soft.xml

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

eac_cpf_soft_xml = client.get("/repositories/2/archival_contexts/softwares/1.xml")
# replace 2 for your repository ID and 1 with your software agent ID. Find these at the URI on the staff interface

with open("eac_cpf_soft.xml", "wb") as file:  # save the file
    file.write(eac_cpf_soft_xml.content)  # write the file content to our file.
    file.close()

# For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_soft_xml.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/softwares/:id.xml ```

<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Software agents cannot be validly mapped to an EAC record, thus exporting is no longer supported.</p>
  
</aside>

__Description__

Get an EAC-CPF representation of a Software agent.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:agent)



## Create an Archival Object



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"archival_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[],
"lang_materials":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"restrictions_apply":false,
"ancestors":[],
"instances":[],
"notes":[],
"ref_id":"278DLJ927",
"level":"subseries",
"title":"Archival Object Title: 11",
"resource":{ "ref":"/repositories/2/resources/3"}}' \
  "http://localhost:8089/repositories/2/archival_objects"

```



__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects ```


__Description__

Create an Archival Object.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:archival_object)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of Archival Objects for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_objects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_objects?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_objects?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/archival_objects ```


__Description__

Get a list of Archival Objects for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:archival_object)]



## Update an Archival Object



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"archival_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[],
"lang_materials":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"restrictions_apply":false,
"ancestors":[],
"instances":[],
"notes":[],
"ref_id":"278DLJ927",
"level":"subseries",
"title":"Archival Object Title: 11",
"resource":{ "ref":"/repositories/2/resources/3"}}' \
  "http://localhost:8089/repositories/2/archival_objects/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id ```


__Description__

Update an Archival Object.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:archival_object)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get an Archival Object by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_objects/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/archival_objects/:id ```


__Description__

Get an Archival Object by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:archival_object)

  	404 -- Not found



## Delete an Archival Object



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/archival_objects/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/archival_objects/:id ```


__Description__

Delete an Archival Object.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Move existing Archival Objects to become children of an Archival Object



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/accept_children?children=BDP950A&position=1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/accept_children ```


__Description__

Move existing Archival Objects to become children of an Archival Object.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>children</code></td>
        <td style="word-break: break-word;">
            The children to move to the Archival Object
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the Archival Object to move children to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The index for the first child to be moved to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Get the children of an Archival Object



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_objects/1/children"

```



__Endpoint__

```[:GET] /repositories/:repo_id/archival_objects/:id/children ```


__Description__

Get the children of an Archival Object.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- a list of archival object references

  	404 -- Not found



## Batch create several Archival Objects as children of an existing Archival Object



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
  ```shell
  curl -H "X-ArchivesSpace-Session: $SESSION"         -d '{
    "jsonmodel_type": "archival_record_children",
    "children": [
        { "jsonmodel_type":"archival_object",
            "external_ids":[],
            "subjects":[],
            "linked_events":[],
            "extents":[],
            "lang_materials":[],
            "dates":[],
            "external_documents":[],
            "rights_statements":[],
            "linked_agents":[],
            "is_slug_auto":true,
            "restrictions_apply":false,
            "ancestors":[],
            "instances":[],
            "notes":[],
            "level":"subseries",
            "title":"Archival Object Title: 1",
            "resource":{ "ref":"/repositories/2/resources/1"}},
        { "jsonmodel_type":"archival_object",
            "external_ids":[],
            "subjects":[],
            "linked_events":[],
            "extents":[],
            "lang_materials":[],
            "dates":[],
            "external_documents":[],
            "rights_statements":[],
            "linked_agents":[],
            "is_slug_auto":true,
            "restrictions_apply":false,
            "ancestors":[],
            "instances":[],
            "notes":[],
            "level":"subseries",
            "title":"Archival Object Title: 2",
            "resource":{ "ref":"/repositories/2/resources/1"}}
    ]
}'           "http://localhost:8089/repositories/2/archival_objects/1/children"

```




__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/children ```


__Description__

Batch create several Archival Objects as children of an existing Archival Object.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the archival object to add children to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:archival_record_children)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Get a list of record types in the graph of an archival object



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_objects/1/models_in_graph"

```



__Endpoint__

```[:GET] /repositories/:repo_id/archival_objects/:id/models_in_graph ```


__Description__

Get a list of record types in the graph of an archival object.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- OK



## Set the parent/position of an Archival Object in a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/parent?parent=1&position=1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/parent ```


__Description__

Set the parent/position of an Archival Object in a tree.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>parent</code></td>
        <td style="word-break: break-word;">
            The parent of this node in the tree
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The position of this node in the tree
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get the previous record in the tree for an Archival Object



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_objects/1/previous"

```



__Endpoint__

```[:GET] /repositories/:repo_id/archival_objects/:id/previous ```


__Description__

Get the previous record in the tree for an Archival Object.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:archival_object)

  	404 -- No previous node



## Publish an Archival Object and all its sub-records and components



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/publish"

```



__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/publish ```


__Description__

Publish an Archival Object and all its sub-records and components.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Suppress this record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/suppressed?suppressed=true"

```



__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/suppressed ```


__Description__

Suppress this record.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>suppressed</code></td>
        <td style="word-break: break-word;">
            Suppression state
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## Unpublish an Archival Object and all its sub-records and components



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/unpublish"

```



__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/unpublish ```


__Description__

Unpublish an Archival Object and all its sub-records and components.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Update this repository's assessment attribute definitions



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/assessment_attribute_definitions"

```



__Endpoint__

```[:POST] /repositories/:repo_id/assessment_attribute_definitions ```


__Description__

Update this repository's assessment attribute definitions.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:assessment_attribute_definitions)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get this repository's assessment attribute definitions



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/assessment_attribute_definitions"

```



__Endpoint__

```[:GET] /repositories/:repo_id/assessment_attribute_definitions ```


__Description__

Get this repository's assessment attribute definitions.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:assessment_attribute_definitions)



## Create an Assessment



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/assessments"

```



__Endpoint__

```[:POST] /repositories/:repo_id/assessments ```


__Description__

Create an Assessment.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:assessment)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## Get a list of Assessments for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/assessments?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/assessments?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/assessments?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/assessments ```


__Description__

Get a list of Assessments for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:assessment)]



## Update an Assessment



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/assessments/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/assessments/:id ```


__Description__

Update an Assessment.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:assessment)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get an Assessment by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/assessments/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/assessments/:id ```


__Description__

Get an Assessment by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:assessment)



## Delete an Assessment



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/assessments/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/assessments/:id ```


__Description__

Delete an Assessment.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Import a batch of records



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"body_stream"' \
  "http://localhost:8089/repositories/2/batch_imports?migration=PR274441352&skip_results=true"

```



__Endpoint__

```[:POST] /repositories/:repo_id/batch_imports ```


__Description__

Import a batch of records.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>migration</code></td>
        <td style="word-break: break-word;">
            Param to indicate we are using a migrator
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>skip_results</code></td>
        <td style="word-break: break-word;">
            If true, don't return the list of created record URIs
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

body_stream

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Create a Classification Term



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification_term",
"publish":true,
"path_from_root":[],
"linked_records":[],
"is_slug_auto":true,
"identifier":"MXBFX",
"title":"Classification Title: 8",
"description":"Description: 8",
"classification":{ "ref":"/repositories/2/classifications/1"}}' \
  "http://localhost:8089/repositories/2/classification_terms"

```



__Endpoint__

```[:POST] /repositories/:repo_id/classification_terms ```


__Description__

Create a Classification Term.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:classification_term)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of Classification Terms for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classification_terms?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classification_terms?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classification_terms?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/classification_terms ```


__Description__

Get a list of Classification Terms for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:classification_term)]



## Update a Classification Term



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification_term",
"publish":true,
"path_from_root":[],
"linked_records":[],
"is_slug_auto":true,
"identifier":"MXBFX",
"title":"Classification Title: 8",
"description":"Description: 8",
"classification":{ "ref":"/repositories/2/classifications/1"}}' \
  "http://localhost:8089/repositories/2/classification_terms/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/classification_terms/:id ```


__Description__

Update a Classification Term.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:classification_term)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get a Classification Term by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classification_terms/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/classification_terms/:id ```


__Description__

Get a Classification Term by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:classification_term)

  	404 -- Not found



## Delete a Classification Term



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/classification_terms/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/classification_terms/:id ```


__Description__

Delete a Classification Term.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Move existing Classification Terms to become children of another Classification Term



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/classification_terms/1/accept_children?children=993SF70589&position=1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/classification_terms/:id/accept_children ```


__Description__

Move existing Classification Terms to become children of another Classification Term.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>children</code></td>
        <td style="word-break: break-word;">
            The children to move to the Classification Term
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the Classification Term to move children to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The index for the first child to be moved to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Get the children of a Classification Term



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classification_terms/1/children"

```



__Endpoint__

```[:GET] /repositories/:repo_id/classification_terms/:id/children ```


__Description__

Get the children of a Classification Term.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- a list of classification term references

  	404 -- Not found



## Set the parent/position of a Classification Term in a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/classification_terms/1/parent?parent=1&position=1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/classification_terms/:id/parent ```


__Description__

Set the parent/position of a Classification Term in a tree.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>parent</code></td>
        <td style="word-break: break-word;">
            The parent of this node in the tree
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The position of this node in the tree
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Create a Classification



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification",
"publish":true,
"path_from_root":[],
"linked_records":[],
"is_slug_auto":true,
"identifier":"SFSB930",
"title":"Classification Title: 2",
"description":"Description: 3"}' \
  "http://localhost:8089/repositories/2/classifications"

```



__Endpoint__

```[:POST] /repositories/:repo_id/classifications ```


__Description__

Create a Classification.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:classification)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of Classifications for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/classifications ```


__Description__

Get a list of Classifications for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:classification)]



## Get a Classification



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id ```


__Description__

Get a Classification.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:classification)



## Update a Classification



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification",
"publish":true,
"path_from_root":[],
"linked_records":[],
"is_slug_auto":true,
"identifier":"SFSB930",
"title":"Classification Title: 2",
"description":"Description: 3"}' \
  "http://localhost:8089/repositories/2/classifications/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/classifications/:id ```


__Description__

Update a Classification.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:classification)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Delete a Classification



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/classifications/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/classifications/:id ```


__Description__

Delete a Classification.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Move existing Classification Terms to become children of a Classification



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/classifications/1/accept_children?children=V253874967358&position=1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/classifications/:id/accept_children ```


__Description__

Move existing Classification Terms to become children of a Classification.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>children</code></td>
        <td style="word-break: break-word;">
            The children to move to the Classification
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the Classification to move children to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The index for the first child to be moved to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Get a Classification tree



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree"

```



__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree ```

<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Call the */tree/{root,waypoint,node} endpoints to traverse record trees.  See backend/app/model/large_tree.rb for further information.</p>
  
</aside>

__Description__

Get a Classification tree.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- OK



## Fetch tree information for an Classification Term record within a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree/node?node_uri=/repositories/2/classification_terms/1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree/node ```


__Description__

Fetch tree information for an Classification Term record within a tree.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>node_uri</code></td>
        <td style="word-break: break-word;">
            The URI of the Classification Term record of interest
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


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



## Fetch tree path from the root record to Classification Terms



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree/node_from_root?node_ids[]=1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree/node_from_root ```


__Description__

Fetch tree path from the root record to Classification Terms.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>node_ids</code></td>
        <td style="word-break: break-word;">
            The IDs of the Classification Term records of interest
            
        </td>
        <td>[Integer]</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns a JSON array describing the path to a node, starting from the root of the tree.  Each path element provides:

  * node -- the URI of the node to next expand

  * offset -- the waypoint number within `node` that contains the next entry in
    the path (or the desired record, if we're at the end of the path)



## Fetch tree information for the top-level classification record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree/root"

```




__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree/root ```


__Description__

Fetch tree information for the top-level classification record.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns a JSON object describing enough information about this tree's root record to render the rest.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint



## Fetch the record slice for a given tree waypoint



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree/waypoint?offset=0&parent_node=/repositories/2/classification_terms/1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree/waypoint ```


__Description__

Fetch the record slice for a given tree waypoint.

  
  
  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>offset</code></td>
        <td style="word-break: break-word;">
            The page of records to return
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>parent_node</code></td>
        <td style="word-break: break-word;">
            The URI of the parent of this waypoint (none for the root record)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent



## Get a Collection Management Record by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/collection_management/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/collection_management/:id ```


__Description__

Get a Collection Management Record by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:collection_management)



## Transfer components from one resource to another



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/component_transfers?target_resource=790XWMI&component=906F246N369"

```



__Endpoint__

```[:POST] /repositories/:repo_id/component_transfers ```


__Description__

Transfer components from one resource to another.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>target_resource</code></td>
        <td style="word-break: break-word;">
            The URI of the resource to transfer into
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>component</code></td>
        <td style="word-break: break-word;">
            The URI of the archival object to transfer
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Get the Preferences records for the current repository and user.



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/current_preferences"

```



__Endpoint__

```[:GET] /repositories/:repo_id/current_preferences ```


__Description__

Get the Preferences records for the current repository and user..

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {(:preference)}



## Create a Custom Report Template



  
    
  
  
    
  

  
    
  
  
    
  
  
  
  ```shell
curl -H 'Content-Type: application/json' \
  -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{
        "lock_version": 0,
        "name": "A New Custom Template",
        "description": "A custom report template returning old accessions sorted by title.",
        "data": "{"fields":{"access_restrictions":{"value":"true"},"accession_date":{"include":"1","narrow_by":"1","range_start":"2011-01-01","range_end":"2019-12-31"},"publish":{"value":"true"},"restrictions_apply":{"value":"true"},"title":{"include":"1"},"use_restrictions":{"value":"true"},"create_time":{"range_start":"","range_end":""},"user_mtime":{"range_start":"","range_end":""}},"sort_by":"title","custom_record_type":"accession"}",
        "limit": 100,
        "jsonmodel_type": "custom_report_template",
        "repository": {
            "ref": "/repositories/2"
        }
      }' \
  "http://localhost:8089/repositories/2/custom_report_templates"

```




__Endpoint__

```[:POST] /repositories/:repo_id/custom_report_templates ```


__Description__

Create a Custom Report Template.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:custom_report_template)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## Get a list of Custom Report Templates



  
    
  

  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/custom_report_templates?page=1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/custom_report_templates ```


__Description__

Get a list of Custom Report Templates.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:custom_report_template)]



## Update a CustomReportTemplate



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
  ```shell
curl -H 'Content-Type: application/json' \
  -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{
        "lock_version": 0,
        "name": "A Newer Custom Template",
        "description": "A custom report template returning old accessions sorted by title.",
        "data": "{"fields":{"access_restrictions":{"value":"true"},"accession_date":{"include":"1","narrow_by":"1","range_start":"2011-01-01","range_end":"2019-12-31"},"publish":{"value":"true"},"restrictions_apply":{"value":"true"},"title":{"include":"1"},"use_restrictions":{"value":"true"},"create_time":{"range_start":"","range_end":""},"user_mtime":{"range_start":"","range_end":""}},"sort_by":"title","custom_record_type":"accession"}",
        "limit": 100,
        "jsonmodel_type": "custom_report_template",
        "repository": {
            "ref": "/repositories/2"
        }
      }' \
  "http://localhost:8089/repositories/2/custom_report_templates/1"

```




__Endpoint__

```[:POST] /repositories/:repo_id/custom_report_templates/:id ```


__Description__

Update a CustomReportTemplate.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:custom_report_template)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a Custom Report Template by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/custom_report_templates/1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/custom_report_templates/:id ```


__Description__

Get a Custom Report Template by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:custom_report_template)



## Delete an Custom Report Template



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/custom_report_templates/1"

```




__Endpoint__

```[:DELETE] /repositories/:repo_id/custom_report_templates/:id ```


__Description__

Delete an Custom Report Template.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Save defaults for a record type



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/default_values/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/default_values/:record_type ```


__Description__

Save defaults for a record type.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>record_type</code></td>
        <td style="word-break: break-word;">
            
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:default_values)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get default values for a record type



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/default_values/1"

```



__Endpoint__

```[:GET] /repositories/:repo_id/default_values/:record_type ```


__Description__

Get default values for a record type.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>record_type</code></td>
        <td style="word-break: break-word;">
            
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Create an Digital Object Component



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object_component",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[],
"lang_materials":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[],
"is_slug_auto":true,
"notes":[],
"component_id":"KY414VI",
"title":"Digital Object Component Title: 6",
"digital_object":{ "ref":"/repositories/2/digital_objects/1"},
"position":7,
"has_unpublished_ancestor":true}' \
  "http://localhost:8089/repositories/2/digital_object_components"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components ```


__Description__

Create an Digital Object Component.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:digital_object_component)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of Digital Object Components for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_object_components?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_object_components?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_object_components?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/digital_object_components ```


__Description__

Get a list of Digital Object Components for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:digital_object_component)]



## Update an Digital Object Component



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object_component",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[],
"lang_materials":[],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"file_versions":[],
"is_slug_auto":true,
"notes":[],
"component_id":"KY414VI",
"title":"Digital Object Component Title: 6",
"digital_object":{ "ref":"/repositories/2/digital_objects/1"},
"position":7,
"has_unpublished_ancestor":true}' \
  "http://localhost:8089/repositories/2/digital_object_components/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components/:id ```


__Description__

Update an Digital Object Component.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:digital_object_component)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get an Digital Object Component by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_object_components/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/digital_object_components/:id ```


__Description__

Get an Digital Object Component by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:digital_object_component)

  	404 -- Not found



## Delete a Digital Object Component



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/digital_object_components/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/digital_object_components/:id ```


__Description__

Delete a Digital Object Component.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Move existing Digital Object Components to become children of a Digital Object Component



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_object_components/1/accept_children?children=910806A22411&position=1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components/:id/accept_children ```


__Description__

Move existing Digital Object Components to become children of a Digital Object Component.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>children</code></td>
        <td style="word-break: break-word;">
            The children to move to the Digital Object Component
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the Digital Object Component to move children to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The index for the first child to be moved to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Batch create several Digital Object Components as children of an existing Digital Object Component



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/digital_object_components/1/children"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components/:id/children ```


__Description__

Batch create several Digital Object Components as children of an existing Digital Object Component.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the digital object component to add children to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:digital_record_children)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Get the children of an Digital Object Component



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_object_components/1/children"

```



__Endpoint__

```[:GET] /repositories/:repo_id/digital_object_components/:id/children ```


__Description__

Get the children of an Digital Object Component.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:digital_object_component)]

  	404 -- Not found



## Set the parent/position of an Digital Object Component in a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_object_components/1/parent?parent=1&position=1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components/:id/parent ```


__Description__

Set the parent/position of an Digital Object Component in a tree.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>parent</code></td>
        <td style="word-break: break-word;">
            The parent of this node in the tree
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The position of this node in the tree
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Suppress this record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_object_components/1/suppressed?suppressed=true"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components/:id/suppressed ```


__Description__

Suppress this record.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>suppressed</code></td>
        <td style="word-break: break-word;">
            Suppression state
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## Create a Digital Object



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"whole",
"number":"71",
"extent_type":"cassettes",
"dimensions":"OSKJE",
"physical_details":"XFYGT"}],
"lang_materials":[{ "jsonmodel_type":"lang_material",
"notes":[],
"language_and_script":{ "jsonmodel_type":"language_and_script",
"language":"csb",
"script":"Nkgb"}}],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"file_versions":[],
"restrictions":false,
"classifications":[],
"notes":[],
"linked_instances":[],
"metadata_rights_declarations":[],
"title":"Digital Object Title: 1",
"digital_object_id":"281FD869991"}' \
  "http://localhost:8089/repositories/2/digital_objects"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects ```


__Description__

Create a Digital Object.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:digital_object)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of Digital Objects for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects ```


__Description__

Get a list of Digital Objects for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:digital_object)]



## Get a Digital Object



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id ```


__Description__

Get a Digital Object.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:digital_object)



## Update a Digital Object



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"digital_object",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"whole",
"number":"71",
"extent_type":"cassettes",
"dimensions":"OSKJE",
"physical_details":"XFYGT"}],
"lang_materials":[{ "jsonmodel_type":"lang_material",
"notes":[],
"language_and_script":{ "jsonmodel_type":"language_and_script",
"language":"csb",
"script":"Nkgb"}}],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"file_versions":[],
"restrictions":false,
"classifications":[],
"notes":[],
"linked_instances":[],
"metadata_rights_declarations":[],
"title":"Digital Object Title: 1",
"digital_object_id":"281FD869991"}' \
  "http://localhost:8089/repositories/2/digital_objects/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id ```


__Description__

Update a Digital Object.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:digital_object)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Delete a Digital Object



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/digital_objects/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/digital_objects/:id ```


__Description__

Delete a Digital Object.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Move existing Digital Object components to become children of a Digital Object



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/accept_children?children=DTLG481&position=1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id/accept_children ```


__Description__

Move existing Digital Object components to become children of a Digital Object.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>children</code></td>
        <td style="word-break: break-word;">
            The children to move to the Digital Object
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the Digital Object to move children to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The index for the first child to be moved to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Batch create several Digital Object Components as children of an existing Digital Object



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/digital_objects/1/children"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id/children ```


__Description__

Batch create several Digital Object Components as children of an existing Digital Object.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:digital_record_children)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Publish a digital object and all its sub-records and components



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/publish"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id/publish ```


__Description__

Publish a digital object and all its sub-records and components.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Suppress this record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/suppressed?suppressed=true"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id/suppressed ```


__Description__

Suppress this record.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>suppressed</code></td>
        <td style="word-break: break-word;">
            Suppression state
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## Transfer this record to a different repository



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/transfer?target_repo=K540852ET"

```



__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id/transfer ```


__Description__

Transfer this record to a different repository.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>target_repo</code></td>
        <td style="word-break: break-word;">
            The URI of the target repository
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- moved



## Get a Digital Object tree



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree"

```



__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree ```

<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Call the */tree/{root,waypoint,node} endpoints to traverse record trees.  See backend/app/model/large_tree.rb for further information.</p>
  
</aside>

__Description__

Get a Digital Object tree.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- OK



## Fetch tree information for an Digital Object Component record within a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree/node?node_uri=/repositories/2/digital_object_components/1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree/node ```


__Description__

Fetch tree information for an Digital Object Component record within a tree.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>node_uri</code></td>
        <td style="word-break: break-word;">
            The URI of the Digital Object Component record of interest
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


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



## Fetch tree paths from the root record to Digital Object Components



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree/node_from_root?node_ids[]=1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree/node_from_root ```


__Description__

Fetch tree paths from the root record to Digital Object Components.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>node_ids</code></td>
        <td style="word-break: break-word;">
            The IDs of the Digital Object Component records of interest
            
        </td>
        <td>[Integer]</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns a JSON array describing the path to a node, starting from the root of the tree.  Each path element provides:

  * node -- the URI of the node to next expand

  * offset -- the waypoint number within `node` that contains the next entry in
    the path (or the desired record, if we're at the end of the path)



## Fetch tree information for the top-level digital object record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree/root"

```




__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree/root ```


__Description__

Fetch tree information for the top-level digital object record.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns a JSON object describing enough information about this tree's root record to render the rest.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint



## Fetch the record slice for a given tree waypoint



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree/waypoint?offset=0&parent_node=/repositories/2/digital_object_components/1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree/waypoint ```


__Description__

Fetch the record slice for a given tree waypoint.

  
  
  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>offset</code></td>
        <td style="word-break: break-word;">
            The page of records to return
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>parent_node</code></td>
        <td style="word-break: break-word;">
            The URI of the parent of this waypoint (none for the root record)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent



## Get metadata for a Dublin Core export



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/digital_objects/dublin_core/48.:fmt/metadata"

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

do_dc = client.get("/repositories/2/digital_objects/dublin_core/48.fmt/metadata")
# replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

print(do_dc_fmt.content)
# Sample output: {"filename":"identifier_youtube_20210218_182435_UTC__dc.xml","mimetype":"application/xml"}

# For error handling, print or log the returned value of client.get with .json() - print(do_dc.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata ```


__Description__

Get metadata for a Dublin Core export.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get a Dublin Core representation of a Digital Object



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/digital_objects/dublin_core/48.xml" --output do_dublincore.xml

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

do_dc = client.get("/repositories/2/digital_objects/dublin_core/48.xml")
# replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

with open("do_dc.xml", "wb") as file:  # save the file
    file.write(do_dc.content)  # write the file content to our file.
    file.close()

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/dublin_core/:id.xml ```


__Description__

Get a Dublin Core representation of a Digital Object.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:digital_object)



## Get metadata for a METS export



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/digital_objects/mets/48.:fmt/metadata"

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

mets_fmt = client.get("/repositories/2/digital_objects/mets/48.fmt/metadata")
# replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

print(mets_fmt.content)
# Sample output: {"filename":"identifier_youtube_20210218_182435_UTC__mets.xml","mimetype":"application/xml"}

# For error handling, print or log the returned value of client.get with .json() - print(mets_fmt.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata ```


__Description__

Get metadata for a METS export.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get a METS representation of a Digital Object



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/digital_objects/mets/48.xml?dmd=PKG410P" --output do_mets.xml

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

mets_xml = client.get("/repositories/2/digital_objects/mets/48.xml",
                      params={"dmd": "PKG410P"})
# replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface
# replace PKG410P with your preferred DMD schema

with open("do_mets.xml", "wb") as file:  # save the file
    file.write(mets_xml.content)  # write the file content to our file.
    file.close()

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/mets/:id.xml ```


__Description__

Get a METS representation of a Digital Object.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>dmd</code></td>
        <td style="word-break: break-word;">
            DMD Scheme to use
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:digital_object)



## Get metadata for a MODS export



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/digital_objects/mods/48.fmt/metadata"

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

mods_fmt = client.get("/repositories/2/digital_objects/mods/48.:fmt/metadata")
# replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

print(mods_fmt.content)
# Sample output: {"filename":"identifier_youtube_20210218_182435_UTC__mods.xml","mimetype":"application/xml"}

# For error handling, print or log the returned value of client.get with .json() - print(mods_fmt.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata ```


__Description__

Get metadata for a MODS export.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get a MODS representation of a Digital Object 



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/digital_objects/mods/48.xml" --output do_mods.xml

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

mods_xml = client.get("/repositories/2/digital_objects/mods/48.xml")
# replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

with open("do_mods.xml", "wb") as file:  # save the file
    file.write(mods_xml.content)  # write the file content to our file.
    file.close()

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/mods/:id.xml ```


__Description__

Get a MODS representation of a Digital Object .

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:digital_object)



## Create an Event



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"event",
"external_ids":[],
"external_documents":[],
"linked_agents":[{ "ref":"/agents/people/2",
"role":"authorizer"}],
"linked_records":[{ "ref":"/repositories/2/accessions/1",
"role":"outcome"}],
"date":{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1994-11-01",
"end":"1994-11-01",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"J568L635G"},
"event_type":"acknowledgement_received"}' \
  "http://localhost:8089/repositories/2/events"

```



__Endpoint__

```[:POST] /repositories/:repo_id/events ```


__Description__

Create an Event.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:event)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of Events for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/events?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/events?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/events?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/events ```


__Description__

Get a list of Events for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:event)]



## Update an Event



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"event",
"external_ids":[],
"external_documents":[],
"linked_agents":[{ "ref":"/agents/people/2",
"role":"authorizer"}],
"linked_records":[{ "ref":"/repositories/2/accessions/1",
"role":"outcome"}],
"date":{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1994-11-01",
"end":"1994-11-01",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"J568L635G"},
"event_type":"acknowledgement_received"}' \
  "http://localhost:8089/repositories/2/events/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/events/:id ```


__Description__

Update an Event.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:event)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get an Event by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/events/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/events/:id ```


__Description__

Get an Event by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:event)

  	404 -- Not found



## Delete an event record



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/events/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/events/:id ```


__Description__

Delete an event record.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Suppress this record from non-managers



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/events/1/suppressed?suppressed=true"

```



__Endpoint__

```[:POST] /repositories/:repo_id/events/:id/suppressed ```


__Description__

Suppress this record from non-managers.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>suppressed</code></td>
        <td style="word-break: break-word;">
            Suppression state
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## Find Archival Objects by ref_id or component_id



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/find_by_id/archival_objects?ref_id=88210V856273&component_id=PYU984F&resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/find_by_id/archival_objects ```


__Description__

Find Archival Objects by ref_id or component_id.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>ref_id</code></td>
        <td style="word-break: break-word;">
            An archival object's Ref ID (param may be repeated)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>component_id</code></td>
        <td style="word-break: break-word;">
            An archival object's component ID (param may be repeated)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- JSON array of refs



## Find Digital Object Components by component_id



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/find_by_id/digital_object_components?component_id=F429M646L&resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/find_by_id/digital_object_components ```


__Description__

Find Digital Object Components by component_id.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>component_id</code></td>
        <td style="word-break: break-word;">
            A digital object component's component ID (param may be repeated)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- JSON array of refs



## Find Digital Objects by digital_object_id



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/find_by_id/digital_objects?digital_object_id=KX8543124&resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/find_by_id/digital_objects ```


__Description__

Find Digital Objects by digital_object_id.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>digital_object_id</code></td>
        <td style="word-break: break-word;">
            A digital object's digital object ID (param may be repeated)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- JSON array of refs



## Find Resources by their identifiers



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/find_by_id/resources?identifier=884JYQF&resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/find_by_id/resources ```


__Description__

Find Resources by their identifiers.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>identifier</code></td>
        <td style="word-break: break-word;">
            A 4-part identifier expressed as a JSON array (of up to 4 strings) comprised of the id_0 to id_3 fields (though empty fields will be handled if not provided)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- JSON array of refs



## Create a group within a repository



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 7",
"member_usernames":[],
"grants_permissions":[],
"group_code":"926200700201S"}' \
  "http://localhost:8089/repositories/2/groups"

```



__Endpoint__

```[:POST] /repositories/:repo_id/groups ```


__Description__

Create a group within a repository.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:group)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- conflict



## Get a list of groups for a repository



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/groups?group_code=XBFAS"

```



__Endpoint__

```[:GET] /repositories/:repo_id/groups ```


__Description__

Get a list of groups for a repository.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>group_code</code></td>
        <td style="word-break: break-word;">
            Get groups by group code
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:resource)]



## Update a group



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 7",
"member_usernames":[],
"grants_permissions":[],
"group_code":"926200700201S"}' \
  "http://localhost:8089/repositories/2/groups/1?with_members=true"

```



__Endpoint__

```[:POST] /repositories/:repo_id/groups/:id ```


__Description__

Update a group.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>with_members</code></td>
        <td style="word-break: break-word;">
            If 'true' (the default) replace the membership list with the list provided
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:group)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}

  	409 -- conflict



## Get a group by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/groups/1?with_members=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/groups/:id ```


__Description__

Get a group by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>with_members</code></td>
        <td style="word-break: break-word;">
            If 'true' (the default) return the list of members with the group
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:group)

  	404 -- Not found



## Delete a group by ID



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/groups/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/groups/:id ```


__Description__

Delete a group by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:group)

  	404 -- Not found



## Create a new job



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"job",
"status":"queued",
"job":{ "jsonmodel_type":"import_job",
"filenames":["M393VQ206",
"417H221QR",
"245F152428V",
"BAK910257"],
"import_type":"marcxml"}}' \
  "http://localhost:8089/repositories/2/jobs"

```



__Endpoint__

```[:POST] /repositories/:repo_id/jobs ```


__Description__

Create a new job.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:job)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a list of Jobs for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/jobs ```


__Description__

Get a list of Jobs for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:job)]



## Delete a Job



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/jobs/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/jobs/:id ```


__Description__

Delete a Job.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Get a Job by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/jobs/:id ```


__Description__

Get a Job by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:job)



## Cancel a Job



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/jobs/1/cancel"

```



__Endpoint__

```[:POST] /repositories/:repo_id/jobs/:id/cancel ```


__Description__

Cancel a Job.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a Job's log by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/1/log?offset=NonNegativeInteger"

```



__Endpoint__

```[:GET] /repositories/:repo_id/jobs/:id/log ```


__Description__

Get a Job's log by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>offset</code></td>
        <td style="word-break: break-word;">
            The byte offset of the log file to show
            
        </td>
        <td>RESTHelpers::NonNegativeInteger</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The section of the import log between 'offset' and the end of file



## Get a list of Job's output files by ID



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/1/output_files"

```



__Endpoint__

```[:GET] /repositories/:repo_id/jobs/:id/output_files ```


__Description__

Get a list of Job's output files by ID.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- An array of output files



## Get a Job's output file by ID



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/1/output_files/1"

```



__Endpoint__

```[:GET] /repositories/:repo_id/jobs/:id/output_files/:file_id ```


__Description__

Get a Job's output file by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>file_id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns the file



## Get a Job's list of created URIs



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/1/records?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/1/records?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/1/records?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/jobs/:id/records ```


__Description__

Get a Job's list of created URIs.

  
  
  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- An array of created records



## Get a list of all active Jobs for a Repository



  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/active?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/jobs/active ```


__Description__

Get a list of all active Jobs for a Repository.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:job)]



## Get a list of all archived Jobs for a Repository



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/archived?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/archived?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/archived?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/jobs/archived ```


__Description__

Get a list of all archived Jobs for a Repository.

  
  
  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:job)]



## List all supported import job types



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/jobs/import_types"

```



__Endpoint__

```[:GET] /repositories/:repo_id/jobs/import_types ```


__Description__

List all supported import job types.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- A list of supported import types



## Create a new job and post input files



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/jobs_with_files?job={"jsonmodel_type"=>"job", "status"=>"queued", "job"=>{"jsonmodel_type"=>"import_job", "filenames"=>["M393VQ206", "417H221QR", "245F152428V", "BAK910257"], "import_type"=>"marcxml"}}&files=UploadFile"

```



__Endpoint__

```[:POST] /repositories/:repo_id/jobs_with_files ```


__Description__

Create a new job and post input files.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>job</code></td>
        <td style="word-break: break-word;">
            
            
        </td>
        <td>JSONModel(:job)</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>files</code></td>
        <td style="word-break: break-word;">
            
            
        </td>
        <td>[RESTHelpers::UploadFile]</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Create a Preferences record



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"preference",
"defaults":{ "jsonmodel_type":"defaults",
"show_suppressed":false,
"publish":false,
"default_values":false,
"note_order":[]}}' \
  "http://localhost:8089/repositories/2/preferences"

```



__Endpoint__

```[:POST] /repositories/:repo_id/preferences ```


__Description__

Create a Preferences record.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:preference)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of Preferences for a Repository and optionally a user



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/preferences?user_id=1"

```



__Endpoint__

```[:GET] /repositories/:repo_id/preferences ```


__Description__

Get a list of Preferences for a Repository and optionally a user.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>user_id</code></td>
        <td style="word-break: break-word;">
            The username to retrieve defaults for
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:preference)]



## Get a Preferences record



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/preferences/1"

```



__Endpoint__

```[:GET] /repositories/:repo_id/preferences/:id ```


__Description__

Get a Preferences record.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:preference)



## Update a Preferences record



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"preference",
"defaults":{ "jsonmodel_type":"defaults",
"show_suppressed":false,
"publish":false,
"default_values":false,
"note_order":[]}}' \
  "http://localhost:8089/repositories/2/preferences/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/preferences/:id ```


__Description__

Update a Preferences record.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:preference)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Delete a Preferences record



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/preferences/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/preferences/:id ```


__Description__

Delete a Preferences record.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Get the default set of Preferences for a Repository and optionally a user



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/preferences/defaults?username=OA611291A"

```



__Endpoint__

```[:GET] /repositories/:repo_id/preferences/defaults ```


__Description__

Get the default set of Preferences for a Repository and optionally a user.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>username</code></td>
        <td style="word-break: break-word;">
            The username to retrieve defaults for
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (defaults)



## Create an RDE template



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/rde_templates"

```



__Endpoint__

```[:POST] /repositories/:repo_id/rde_templates ```


__Description__

Create an RDE template.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:rde_template)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of RDE Templates



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/rde_templates"

```



__Endpoint__

```[:GET] /repositories/:repo_id/rde_templates ```


__Description__

Get a list of RDE Templates.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:rde_template)]



## Get an RDE template record



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/rde_templates/1"

```



__Endpoint__

```[:GET] /repositories/:repo_id/rde_templates/:id ```


__Description__

Get an RDE template record.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:rde_template)



## Delete an RDE Template



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/rde_templates/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/rde_templates/:id ```


__Description__

Delete an RDE Template.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Require fields for a record type



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/required_fields/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/required_fields/:record_type ```


__Description__

Require fields for a record type.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>record_type</code></td>
        <td style="word-break: break-word;">
            
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:required_fields)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get required fields for a record type



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/required_fields/1"

```



__Endpoint__

```[:GET] /repositories/:repo_id/required_fields/:record_type ```


__Description__

Get required fields for a record type.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>record_type</code></td>
        <td style="word-break: break-word;">
            
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get export metadata for a Resource Description



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/resources/resource_descriptions/577.:fmt/metadata?fmt=864442169P755"

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

res_fmt = client.get("/repositories/2/resource_descriptions/577.:fmt/metadata",
                     params={"fmt": "864442169P755"})
# replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface
# set fmt to the format of the request you would like to export

print(res_fmt.content)
# Sample output: {"filename":"identifier_20210218_182435_UTC__ead.fmt","mimetype":"application/:fmt"}

# For error handling, print or log the returned value of client.get with .json() - print(res_fmt.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_descriptions/:id.:fmt/metadata ```


__Description__

Get export metadata for a Resource Description.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>fmt</code></td>
        <td style="word-break: break-word;">
            Format of the request
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get a PDF representation of a Resource



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/resource_descriptions/577.pdf?include_unpublished=false&include_daos=true&numbered_cs=true&print_pdf=false&ead3=false" //
--output ead.pdf

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

ead_pdf = client.get("repositories/2/resource_descriptions/577.pdf",
                      params={"include_unpublished": False,
                              "include_daos": True,
                              "numbered_cs": True,
                              "print_pdf": True,
                              "ead3": False})
# replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface
# set parameters to True or False

with open("ead.pdf", "wb") as file:  # save the file
    file.write(ead_pdf.content)  # write the file content to our file.
    file.close()

# For error handling, print or log the returned value of client.get with .json() - print(ead_pdf.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_descriptions/:id.pdf ```


__Description__

Get a PDF representation of a Resource.

  
  
  
  
  
  
  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>include_unpublished</code></td>
        <td style="word-break: break-word;">
            Include unpublished records
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>include_daos</code></td>
        <td style="word-break: break-word;">
            Include digital objects in dao tags
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>numbered_cs</code></td>
        <td style="word-break: break-word;">
            Use numbered <c> tags in ead
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>print_pdf</code></td>
        <td style="word-break: break-word;">
            Print EAD to pdf
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>ead3</code></td>
        <td style="word-break: break-word;">
            Export using EAD3 schema
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:resource)



## Get an EAD representation of a Resource



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/resource_descriptions/577.xml?include_unpublished=false&include_daos=true&numbered_cs=true&print_pdf=false&ead3=false" //
--output ead.xml

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

ead_xml = client.get("repositories/2/resource_descriptions/577.xml",
                     params={"include_unpublished": False,
                             "include_daos": True,
                             "numbered_cs": True,
                             "print_pdf": False,
                             "ead3": False})
# replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface
# set parameters to True or False

with open("ead.xml", "wb") as file:  # save the file
    file.write(ead_xml.content)  # write the file content to our file.
    file.close()

# For error handling, print or log the returned value of client.get with .json() - print(ead_xml.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_descriptions/:id.xml ```


__Description__

Get an EAD representation of a Resource.

  
  
  
  
  
  
  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>include_unpublished</code></td>
        <td style="word-break: break-word;">
            Include unpublished records
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>include_daos</code></td>
        <td style="word-break: break-word;">
            Include digital objects in dao tags
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>numbered_cs</code></td>
        <td style="word-break: break-word;">
            Use numbered <c> tags in ead
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>print_pdf</code></td>
        <td style="word-break: break-word;">
            Print EAD to pdf
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>ead3</code></td>
        <td style="word-break: break-word;">
            Export using EAD3 schema
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:resource)



## Get export metadata for Resource labels



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/resource_labels/577.:fmt/metadata" --output labels.fmt

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

labels_fmt = client.get("/repositories/2/resource_labels/577.:fmt/metadata")
# replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface

print(labels_fmt.content)
# Sample output: {"filename":"identifier_20210218_182435_UTC__labels.tsv","mimetype":"text/tab-separated-values"}

# For error handling, print or log the returned value of client.get with .json() - print(labels_fmt.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_labels/:id.:fmt/metadata ```


__Description__

Get export metadata for Resource labels.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get a tsv list of printable labels for a Resource



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/resource_labels/577.tsv" --output container_labels.tsv

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

request_labels = client.get("repositories/2/resource_labels/577.tsv")
# replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface

with open("container_labels.tsv", "wb") as local_file:
    local_file.write(request_labels.content)  # write the file content to our file.
    local_file.close()

# For error handling, print or log the returned value of client.get with .json() - print(request_labels.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_labels/:id.tsv ```


__Description__

Get a tsv list of printable labels for a Resource.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:resource)



## Create a Resource



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"resource",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"part",
"number":"71",
"extent_type":"gigabytes",
"dimensions":"B203799UY",
"physical_details":"K858764S612"}],
"lang_materials":[{ "jsonmodel_type":"lang_material",
"notes":[],
"language_and_script":{ "jsonmodel_type":"language_and_script",
"language":"tam",
"script":"Lana"}}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1974-05-28",
"end":"1974-05-28",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"ORWA961"},
{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1974-06-20",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"FVRCK"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"QPGEF",
"description":"EW94855R"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"text",
"sub_container":{ "jsonmodel_type":"sub_container",
"top_container":{ "ref":"/repositories/2/top_containers/4"},
"type_2":"folder",
"indicator_2":"266FQ148I",
"barcode_2":"LS62V742",
"type_3":"carton",
"indicator_3":"NF145364W"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"metadata_rights_declarations":[],
"title":"Resource Title: <emph render='italic'>2</emph>",
"id_0":"U810V283640",
"level":"subseries",
"finding_aid_description_rules":"cco",
"ead_id":"675JIQU",
"finding_aid_date":"72467793U313",
"finding_aid_series_statement":"CW513QL",
"finding_aid_language":"amh",
"finding_aid_script":"Ogam",
"finding_aid_note":"613NXJO",
"ead_location":"T798623PX"}' \
  "http://localhost:8089/repositories/2/resources"

```



__Endpoint__

```[:POST] /repositories/:repo_id/resources ```


__Description__

Create a Resource.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:resource)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of Resources for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/resources ```


__Description__

Get a list of Resources for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:resource)]



## Get a Resource



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id ```


__Description__

Get a Resource.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:resource)



## Update a Resource



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"resource",
"external_ids":[],
"subjects":[],
"linked_events":[],
"extents":[{ "jsonmodel_type":"extent",
"portion":"part",
"number":"71",
"extent_type":"gigabytes",
"dimensions":"B203799UY",
"physical_details":"K858764S612"}],
"lang_materials":[{ "jsonmodel_type":"lang_material",
"notes":[],
"language_and_script":{ "jsonmodel_type":"language_and_script",
"language":"tam",
"script":"Lana"}}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1974-05-28",
"end":"1974-05-28",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"ORWA961"},
{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"1974-06-20",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"FVRCK"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"QPGEF",
"description":"EW94855R"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"text",
"sub_container":{ "jsonmodel_type":"sub_container",
"top_container":{ "ref":"/repositories/2/top_containers/4"},
"type_2":"folder",
"indicator_2":"266FQ148I",
"barcode_2":"LS62V742",
"type_3":"carton",
"indicator_3":"NF145364W"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"metadata_rights_declarations":[],
"title":"Resource Title: <emph render='italic'>2</emph>",
"id_0":"U810V283640",
"level":"subseries",
"finding_aid_description_rules":"cco",
"ead_id":"675JIQU",
"finding_aid_date":"72467793U313",
"finding_aid_series_statement":"CW513QL",
"finding_aid_language":"amh",
"finding_aid_script":"Ogam",
"finding_aid_note":"613NXJO",
"ead_location":"T798623PX"}' \
  "http://localhost:8089/repositories/2/resources/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id ```


__Description__

Update a Resource.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:resource)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Delete a Resource



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/resources/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/resources/:id ```


__Description__

Delete a Resource.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Move existing Archival Objects to become children of a Resource



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/accept_children?children=OA67R363&position=1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id/accept_children ```


__Description__

Move existing Archival Objects to become children of a Resource.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>children</code></td>
        <td style="word-break: break-word;">
            The children to move to the Resource
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the Resource to move children to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>position</code></td>
        <td style="word-break: break-word;">
            The index for the first child to be moved to
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Batch create several Archival Objects as children of an existing Resource



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
  ```shell
  curl -H "X-ArchivesSpace-Session: $SESSION"         -d '{
    "jsonmodel_type": "archival_record_children",
    "children": [
        { "jsonmodel_type":"archival_object",
            "external_ids":[],
            "subjects":[],
            "linked_events":[],
            "extents":[],
            "lang_materials":[],
            "dates":[],
            "external_documents":[],
            "rights_statements":[],
            "linked_agents":[],
            "is_slug_auto":true,
            "restrictions_apply":false,
            "ancestors":[],
            "instances":[],
            "notes":[],
            "level":"subseries",
            "title":"Archival Object Title: 1",
            "resource":{ "ref":"/repositories/2/resources/1"}},
        { "jsonmodel_type":"archival_object",
            "external_ids":[],
            "subjects":[],
            "linked_events":[],
            "extents":[],
            "lang_materials":[],
            "dates":[],
            "external_documents":[],
            "rights_statements":[],
            "linked_agents":[],
            "is_slug_auto":true,
            "restrictions_apply":false,
            "ancestors":[],
            "instances":[],
            "notes":[],
            "level":"subseries",
            "title":"Archival Object Title: 2",
            "resource":{ "ref":"/repositories/2/resources/1"}}
    ]
}'           "http://localhost:8089/repositories/2/resources/1/children"

```




__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id/children ```


__Description__

Batch create several Archival Objects as children of an existing Resource.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:archival_record_children)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- {:error => (description of error)}



## Get a list of record types in the graph of a resource



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/models_in_graph"

```



__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/models_in_graph ```


__Description__

Get a list of record types in the graph of a resource.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- OK



## Get the list of URIs of this published resource and all published archival objects contained within.Ordered by tree order (i.e. if you fully expanded the record tree and read from top to bottom)



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/ordered_records"

```



__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/ordered_records ```


__Description__

Get the list of URIs of this published resource and all published archival objects contained within.Ordered by tree order (i.e. if you fully expanded the record tree and read from top to bottom).

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- JSONModel(:resource_ordered_records)



## Publish a resource and all its sub-records and components



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/publish"

```



__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id/publish ```


__Description__

Publish a resource and all its sub-records and components.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Suppress this record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/suppressed?suppressed=true"

```



__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id/suppressed ```


__Description__

Suppress this record.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>suppressed</code></td>
        <td style="word-break: break-word;">
            Suppression state
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}



## Get a CSV template useful for bulk-creating containers for archival objects of a resource



  
    
  
  
    
  

  
    
  
  
    
  
  
  ```shell
# Saves the csv to file 'resource_1_top_container_creation.csv'
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/templates/top_container_creation.csv" \
  > resource_1_top_container_creation.csv

```


```python
from asnake.client import ASnakeClient

client = ASnakeClient()
client.authorize()

with open('resource_1_top_container_creation.csv', 'wb') as file:
    resp = client.get('repositories/2/resources/1/templates/top_container_creation.csv')
    if resp.status_code == 200:
        file.write(resp.content)

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/templates/top_container_creation.csv ```


__Description__

Get a CSV template useful for bulk-creating containers for archival objects of a resource.
<br>
<br>
This method returns a spreadsheet representing all the archival objects in a resource, with the following  fields:

* Reference Fields (Non-editable):
  * Archival Object: ID, Ref ID, and Component ID
  * Resource: Title and Identifier
* Editable Fields:
   * Top Container: Instance type, Type, Indicator, and Barcode
   * Child Container: Type, Indicator, and Barcode
   * Location: ID (the location must already exist in the system)


  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The CSV template



## Get Top Containers linked to a published resource and published archival ojbects contained within.



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/top_containers?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/top_containers ```


__Description__

Get Top Containers linked to a published resource and published archival ojbects contained within..

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- a list of linked top containers

  	404 -- Not found



## Transfer this record to a different repository



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/transfer?target_repo=XH598327220"

```



__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id/transfer ```


__Description__

Transfer this record to a different repository.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>target_repo</code></td>
        <td style="word-break: break-word;">
            The URI of the target repository
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- moved



## Get a Resource tree



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree?limit_to=U106CSG"

```



__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree ```

<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Call the */tree/{root,waypoint,node} endpoints to traverse record trees.  See backend/app/model/large_tree.rb for further information.</p>
  
</aside>

__Description__

Get a Resource tree.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>limit_to</code></td>
        <td style="word-break: break-word;">
            An Archival Object URI or 'root'
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- OK



## Fetch tree information for an Archival Object record within a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree/node?node_uri=/repositories/2/archival_objects/1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree/node ```


__Description__

Fetch tree information for an Archival Object record within a tree.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>node_uri</code></td>
        <td style="word-break: break-word;">
            The URI of the Archival Object record of interest
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


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



## Fetch tree paths from the root record to Archival Objects



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree/node_from_root?node_ids[]=1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree/node_from_root ```


__Description__

Fetch tree paths from the root record to Archival Objects.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>node_ids</code></td>
        <td style="word-break: break-word;">
            The IDs of the Archival Object records of interest
            
        </td>
        <td>[Integer]</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns a JSON array describing the path to a node, starting from the root of the tree.  Each path element provides:

  * node -- the URI of the node to next expand

  * offset -- the waypoint number within `node` that contains the next entry in
    the path (or the desired record, if we're at the end of the path)



## Fetch tree information for the top-level resource record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree/root"

```




__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree/root ```


__Description__

Fetch tree information for the top-level resource record.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns a JSON object describing enough information about this tree's root record to render the rest.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint



## Fetch the record slice for a given tree waypoint



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree/waypoint?offset=0&parent_node=/repositories/2/archival_objects/1"

```




__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree/waypoint ```


__Description__

Fetch the record slice for a given tree waypoint.

  
  
  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>offset</code></td>
        <td style="word-break: break-word;">
            The page of records to return
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>parent_node</code></td>
        <td style="word-break: break-word;">
            The URI of the parent of this waypoint (none for the root record)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>published_only</code></td>
        <td style="word-break: break-word;">
            Whether to restrict to published/unsuppressed items
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent



## Unpublish a resource and all its sub-records and components



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/unpublish"

```



__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id/unpublish ```


__Description__

Unpublish a resource and all its sub-records and components.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Get metadata for a MARC21 export



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/resources/marc21/577.:fmt/metadata?include_unpublished_marc=true"

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

marc21_fmt = client.get("/repositories/2/resources/marc21/577.:fmt/metadata",
                        params={"include_unpublished_marc": True})
# replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface
# set include_unpublished_marc to True or False

print(marc21_fmt.content)
# Sample output: {"filename":"identifier_20210218_182435_UTC__marc21.xml","mimetype":"application/xml"}

# For error handling, print or log the returned value of client.get with .json() - print(marc21_fmt.json())

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/marc21/:id.:fmt/metadata ```


__Description__

Get metadata for a MARC21 export.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>include_unpublished_marc</code></td>
        <td style="word-break: break-word;">
            Include unpublished notes
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- The export metadata



## Get a MARC 21 representation of a Resource



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  ```shell
curl -s -F password="admin" "http://localhost:8089/users/admin/login"
set SESSION="session_id"
curl -H "X-ArchivesSpace-Session: $SESSION" //
"http://localhost:8089/repositories/2/resources/marc21/577.xml?include_unpublished_marc=true;include_unpublished_notes=false" //
--output marc21.xml

```


```python
from asnake.client import ASnakeClient  # import the ArchivesSnake client

client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
# replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

client.authorize()  # authorizes the client

marc21_xml = client.get("/repositories/2/resources/marc21/577.xml",
                        params={"include_unpublished_marc": True,
                                "include_unpublished_notes": False})
# replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface
# set parameters to True or False

with open("marc21.xml", "wb") as file:  # save the file
    file.write(marc21_xml.content)  # write the file content to our file.
    file.close()

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/marc21/:id.xml ```


__Description__

Get a MARC 21 representation of a Resource.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>include_unpublished_marc</code></td>
        <td style="word-break: break-word;">
            Include unpublished notes
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:resource)



## Search this repository



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"WJQ40460"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"KLNIJ"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"228S786TL"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"G917642826"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"985H286HR"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"LH297O71"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"E337W452R"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"806NE491396"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"679FWRT"' \
  "http://localhost:8089/repositories/2/search?q=WJQ40460&aq=["Example Missing"]&type=KLNIJ&sort=228S786TL&facet=G917642826&facet_mincount=1&filter=["Example Missing"]&filter_query=985H286HR&exclude=LH297O71&hl=true&root_record=E337W452R&dt=806NE491396&fields=679FWRT"
  

```



__Endpoint__

```[:GET, :POST] /repositories/:repo_id/search ```


__Description__

Search this repository.

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
</ul>
</aside>

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>q</code></td>
        <td style="word-break: break-word;">
            A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>aq</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>type</code></td>
        <td style="word-break: break-word;">
            The record type to search (defaults to all types if not specified)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>sort</code></td>
        <td style="word-break: break-word;">
            The attribute to sort and the direction e.g. &sort=title desc&...
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet</code></td>
        <td style="word-break: break-word;">
            The list of the fields to produce facets for
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet_mincount</code></td>
        <td style="word-break: break-word;">
            The minimum count for a facet field to be included in the response
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query to filter by
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter_query</code></td>
        <td style="word-break: break-word;">
            Search queries to be applied as a filter to the results.
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>exclude</code></td>
        <td style="word-break: break-word;">
            A list of document IDs that should be excluded from results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>hl</code></td>
        <td style="word-break: break-word;">
            Whether to use highlighting
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>root_record</code></td>
        <td style="word-break: break-word;">
            Search within a collection of records (defined by the record at the root of the tree)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>dt</code></td>
        <td style="word-break: break-word;">
            Format to return (JSON default)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>fields</code></td>
        <td style="word-break: break-word;">
            The list of fields to include in the results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- 



## Create a top container



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"top_container",
"active_restrictions":[],
"container_locations":[],
"series":[],
"collection":[],
"indicator":"130UI788D",
"type":"box",
"barcode":"dfd3661ae04731b705c32e3af31585d1",
"ils_holding_id":"SJ885I20",
"ils_item_id":"UR88943Q",
"exported_to_ils":"2021-09-20T19:04:39-04:00"}' \
  "http://localhost:8089/repositories/2/top_containers"

```



__Endpoint__

```[:POST] /repositories/:repo_id/top_containers ```


__Description__

Create a top container.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:top_container)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## Get a list of TopContainers for a Repository



  
    
  

  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/top_containers?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/top_containers?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/top_containers?all_ids=true"

```



__Endpoint__

```[:GET] /repositories/:repo_id/top_containers ```


__Description__

Get a list of TopContainers for a Repository.

  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>


<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:top_container)]



## Update a top container



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"top_container",
"active_restrictions":[],
"container_locations":[],
"series":[],
"collection":[],
"indicator":"130UI788D",
"type":"box",
"barcode":"dfd3661ae04731b705c32e3af31585d1",
"ils_holding_id":"SJ885I20",
"ils_item_id":"UR88943Q",
"exported_to_ils":"2021-09-20T19:04:39-04:00"}' \
  "http://localhost:8089/repositories/2/top_containers/1"

```



__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/:id ```


__Description__

Update a top container.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:top_container)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a top container by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/top_containers/1?resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /repositories/:repo_id/top_containers/:id ```


__Description__

Get a top container by ID.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:top_container)



## Delete a top container



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/repositories/2/top_containers/1"

```



__Endpoint__

```[:DELETE] /repositories/:repo_id/top_containers/:id ```


__Description__

Delete a top container.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Update container profile for a batch of top containers



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/top_containers/batch/container_profile?ids=1&container_profile_uri=LQAKT"

```



__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/batch/container_profile ```


__Description__

Update container profile for a batch of top containers.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>ids</code></td>
        <td style="word-break: break-word;">
            
            
        </td>
        <td>[Integer]</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>container_profile_uri</code></td>
        <td style="word-break: break-word;">
            The uri of the container profile
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Update ils_holding_id for a batch of top containers



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/top_containers/batch/ils_holding_id?ids=1&ils_holding_id=D743831543V"

```



__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/batch/ils_holding_id ```


__Description__

Update ils_holding_id for a batch of top containers.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>ids</code></td>
        <td style="word-break: break-word;">
            
            
        </td>
        <td>[Integer]</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>ils_holding_id</code></td>
        <td style="word-break: break-word;">
            Value to set for ils_holding_id
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Update location for a batch of top containers



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
 -d 'ids[]=[1,2,3,4,5]' \
 -d 'location_uri=locations/1234' \
 "http://localhost:8089/repositories/2/top_containers/batch/location"

```


```python
client = ASnakeClient()
client.post('repositories/2/top_containers/batch/location',
      params={ 'ids': [1,2,3,4,5],
               'location_uri': 'locations/1234' })

```


__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/batch/location ```


__Description__

Update location for a batch of top containers.
<br>
<br>
This route takes the `ids` of one or more containers, and associates the containers
with the location referenced by `location_uri`.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>ids</code></td>
        <td style="word-break: break-word;">
            
            
        </td>
        <td>[Integer]</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>location_uri</code></td>
        <td style="word-break: break-word;">
            The uri of the location
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Bulk update barcodes



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"187I490W739"' \
  "http://localhost:8089/repositories/2/top_containers/bulk/barcodes"

```



__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/bulk/barcodes ```


__Description__

Bulk update barcodes.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

String

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Bulk update locations



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"340715FGM"' \
  "http://localhost:8089/repositories/2/top_containers/bulk/locations"

```



__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/bulk/locations ```


__Description__

Bulk update locations.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

String

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Search for top containers



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/top_containers/search?q=GHCN877&aq=["Example Missing"]&type=84PNEI&sort=K532949177D&facet=ALECI&facet_mincount=1&filter=["Example Missing"]&filter_query=OUO397Q&exclude=635582G404L&hl=true&root_record=935855R946150&dt=TMNSI&fields=UJM341F"

```



__Endpoint__

```[:GET] /repositories/:repo_id/top_containers/search ```


__Description__

Search for top containers.

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>q</code></td>
        <td style="word-break: break-word;">
            A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>aq</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>type</code></td>
        <td style="word-break: break-word;">
            The record type to search (defaults to all types if not specified)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>sort</code></td>
        <td style="word-break: break-word;">
            The attribute to sort and the direction e.g. &sort=title desc&...
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet</code></td>
        <td style="word-break: break-word;">
            The list of the fields to produce facets for
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet_mincount</code></td>
        <td style="word-break: break-word;">
            The minimum count for a facet field to be included in the response
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query to filter by
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter_query</code></td>
        <td style="word-break: break-word;">
            Search queries to be applied as a filter to the results.
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>exclude</code></td>
        <td style="word-break: break-word;">
            A list of document IDs that should be excluded from results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>hl</code></td>
        <td style="word-break: break-word;">
            Whether to use highlighting
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>root_record</code></td>
        <td style="word-break: break-word;">
            Search within a collection of records (defined by the record at the root of the tree)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>dt</code></td>
        <td style="word-break: break-word;">
            Format to return (JSON default)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>fields</code></td>
        <td style="word-break: break-word;">
            The list of fields to include in the results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:top_container)]



## Transfer this record to a different repository



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/transfer?target_repo=N727350I363"

```



__Endpoint__

```[:POST] /repositories/:repo_id/transfer ```


__Description__

Transfer this record to a different repository.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>target_repo</code></td>
        <td style="word-break: break-word;">
            The URI of the target repository
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- moved



## Get a user's details including their groups for the current repository



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/users/1"

```



__Endpoint__

```[:GET] /repositories/:repo_id/users/:id ```


__Description__

Get a user's details including their groups for the current repository.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The username id to fetch
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository ID
            
            <br>
            <b>Note: </b> The Repository must exist
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:user)



## Create a Repository with an agent representation



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"repository_with_agent",
"repository":{ "jsonmodel_type":"repository",
"name":"Description: 6",
"is_slug_auto":true,
"repo_code":"ASPACE REPO 3 -- 719662",
"org_code":"D814N666A",
"image_url":"http://www.example-12-1632179083.com",
"url":"http://www.example-13-1632179083.com",
"country":"US"},
"agent_representation":{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number_type":"home",
"number":"688 46464 60677 557",
"ext":"RCKGO"}],
"notes":[{ "jsonmodel_type":"note_contact_note",
"date_of_contact":"T18080661996",
"contact_notes":"EGP788L"}],
"is_representative":false,
"name":"Name Number 10",
"address_2":"291ROXL",
"country":"927O548VJ",
"post_code":"YL414118188",
"fax":"901WA708P",
"email":"OXETC"}],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"conference_meeting":false,
"jurisdiction":false,
"parallel_names":[],
"rules":"dacs",
"primary_name":"Name Number 9",
"subordinate_name_1":"ROO833945",
"subordinate_name_2":"EI980GL",
"number":"619N410JN",
"sort_name":"SORT y - 7",
"qualifier":"J880IJ290",
"dates":"JEGBY",
"authority_id":"http://www.example-14-1632179083.com",
"source":"ingest"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}}' \
  "http://localhost:8089/repositories/with_agent"

```



__Endpoint__

```[:POST] /repositories/with_agent ```


__Description__

Create a Repository with an agent representation.

  
  


__Accepts Payload of Type__

JSONModel(:repository_with_agent)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	403 -- access_denied



## Get a Repository by ID, including its agent representation



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/with_agent/1"

```



__Endpoint__

```[:GET] /repositories/with_agent/:id ```


__Description__

Get a Repository by ID, including its agent representation.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:repository_with_agent)

  	404 -- Not found



## Update a repository with an agent representation



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"repository_with_agent",
"repository":{ "jsonmodel_type":"repository",
"name":"Description: 6",
"is_slug_auto":true,
"repo_code":"ASPACE REPO 3 -- 719662",
"org_code":"D814N666A",
"image_url":"http://www.example-12-1632179083.com",
"url":"http://www.example-13-1632179083.com",
"country":"US"},
"agent_representation":{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number_type":"home",
"number":"688 46464 60677 557",
"ext":"RCKGO"}],
"notes":[{ "jsonmodel_type":"note_contact_note",
"date_of_contact":"T18080661996",
"contact_notes":"EGP788L"}],
"is_representative":false,
"name":"Name Number 10",
"address_2":"291ROXL",
"country":"927O548VJ",
"post_code":"YL414118188",
"fax":"901WA708P",
"email":"OXETC"}],
"agent_record_controls":[],
"agent_alternate_sets":[],
"agent_conventions_declarations":[],
"agent_other_agency_codes":[],
"agent_maintenance_histories":[],
"agent_record_identifiers":[],
"agent_identifiers":[],
"agent_sources":[],
"agent_places":[],
"agent_occupations":[],
"agent_functions":[],
"agent_topics":[],
"agent_resources":[],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"used_languages":[],
"metadata_rights_declarations":[],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[{ "jsonmodel_type":"structured_date_label",
"date_type_structured":"single",
"date_label":"existence",
"structured_date_single":{ "jsonmodel_type":"structured_date_single",
"date_role":"begin",
"date_expression":"Yesterday",
"date_standardized":"2019-06-01",
"date_standardized_type":"standard"},
"date_certainty":"approximate",
"date_era":"ce",
"date_calendar":"gregorian"}],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"conference_meeting":false,
"jurisdiction":false,
"parallel_names":[],
"rules":"dacs",
"primary_name":"Name Number 9",
"subordinate_name_1":"ROO833945",
"subordinate_name_2":"EI980GL",
"number":"619N410JN",
"sort_name":"SORT y - 7",
"qualifier":"J880IJ290",
"dates":"JEGBY",
"authority_id":"http://www.example-14-1632179083.com",
"source":"ingest"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}}' \
  "http://localhost:8089/repositories/with_agent/1"

```



__Endpoint__

```[:POST] /repositories/with_agent/:id ```


__Description__

Update a repository with an agent representation.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:repository_with_agent)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get all ArchivesSpace schemas




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/schemas"

```



__Endpoint__

```[:GET] /schemas ```


__Description__

Get all ArchivesSpace schemas.




__Returns__

  	200 -- ArchivesSpace (schemas)



## Get an ArchivesSpace schema



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/schemas/1"

```



__Endpoint__

```[:GET] /schemas/:schema ```


__Description__

Get an ArchivesSpace schema.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>schema</code></td>
        <td style="word-break: break-word;">
            Schema name to retrieve
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- ArchivesSpace (:schema)

  	404 -- Schema not found



## Search this archive



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"ID864Q390"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"P112AC485"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"IT657GE"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"WH117240N"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"CFO862A"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"FHK650148"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"39N711T301"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"HNY808U"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"E622369RV"' \
  "http://localhost:8089/search?q=ID864Q390&aq=["Example Missing"]&type=P112AC485&sort=IT657GE&facet=WH117240N&facet_mincount=1&filter=["Example Missing"]&filter_query=CFO862A&exclude=FHK650148&hl=true&root_record=39N711T301&dt=HNY808U&fields=E622369RV"
  

```



__Endpoint__

```[:GET, :POST] /search ```


__Description__

Search this archive.

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
</ul>
</aside>

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>q</code></td>
        <td style="word-break: break-word;">
            A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>aq</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>type</code></td>
        <td style="word-break: break-word;">
            The record type to search (defaults to all types if not specified)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>sort</code></td>
        <td style="word-break: break-word;">
            The attribute to sort and the direction e.g. &sort=title desc&...
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet</code></td>
        <td style="word-break: break-word;">
            The list of the fields to produce facets for
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet_mincount</code></td>
        <td style="word-break: break-word;">
            The minimum count for a facet field to be included in the response
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query to filter by
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter_query</code></td>
        <td style="word-break: break-word;">
            Search queries to be applied as a filter to the results.
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>exclude</code></td>
        <td style="word-break: break-word;">
            A list of document IDs that should be excluded from results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>hl</code></td>
        <td style="word-break: break-word;">
            Whether to use highlighting
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>root_record</code></td>
        <td style="word-break: break-word;">
            Search within a collection of records (defined by the record at the root of the tree)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>dt</code></td>
        <td style="word-break: break-word;">
            Format to return (JSON default)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>fields</code></td>
        <td style="word-break: break-word;">
            The list of fields to include in the results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- 



## Search across Location Profiles



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/search/location_profile?q=A992KBO&aq=["Example Missing"]&type=XJHIX&sort=RFQEQ&facet=JJ963722K&facet_mincount=1&filter=["Example Missing"]&filter_query=OC622IB&exclude=HPP888591&hl=true&root_record=EE58873583&dt=350XD200458&fields=YKWVS?page=1&page_size=10"

```



__Endpoint__

```[:GET] /search/location_profile ```


__Description__

Search across Location Profiles.

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
</ul>
</aside>

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>q</code></td>
        <td style="word-break: break-word;">
            A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>aq</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>type</code></td>
        <td style="word-break: break-word;">
            The record type to search (defaults to all types if not specified)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>sort</code></td>
        <td style="word-break: break-word;">
            The attribute to sort and the direction e.g. &sort=title desc&...
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet</code></td>
        <td style="word-break: break-word;">
            The list of the fields to produce facets for
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet_mincount</code></td>
        <td style="word-break: break-word;">
            The minimum count for a facet field to be included in the response
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query to filter by
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter_query</code></td>
        <td style="word-break: break-word;">
            Search queries to be applied as a filter to the results.
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>exclude</code></td>
        <td style="word-break: break-word;">
            A list of document IDs that should be excluded from results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>hl</code></td>
        <td style="word-break: break-word;">
            Whether to use highlighting
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>root_record</code></td>
        <td style="word-break: break-word;">
            Search within a collection of records (defined by the record at the root of the tree)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>dt</code></td>
        <td style="word-break: break-word;">
            Format to return (JSON default)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>fields</code></td>
        <td style="word-break: break-word;">
            The list of fields to include in the results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- 



## Find the tree view for a particular archival record



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/search/published_tree?node_uri=164JTTC"

```



__Endpoint__

```[:GET] /search/published_tree ```


__Description__

Find the tree view for a particular archival record.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>node_uri</code></td>
        <td style="word-break: break-word;">
            The URI of the archival record to find the tree view for
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- OK

  	404 -- Not found



## Return the counts of record types of interest by repository



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"I287M420987"' \
  "http://localhost:8089/search/record_types_by_repository?record_types=I287M420987&repo_uri=F582HQB"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"F582HQB"' \
  "http://localhost:8089/search/record_types_by_repository?record_types=I287M420987&repo_uri=F582HQB"
  

```



__Endpoint__

```[:GET, :POST] /search/record_types_by_repository ```


__Description__

Return the counts of record types of interest by repository.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>record_types</code></td>
        <td style="word-break: break-word;">
            The list of record types to tally
            
        </td>
        <td>[String]</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>repo_uri</code></td>
        <td style="word-break: break-word;">
            An optional repository URI.  If given, just return counts for the single repository
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- If repository is given, returns a map like {'record_type' => <count>}.  Otherwise, {'repo_uri' => {'record_type' => <count>}}



## Return a set of records by URI



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"384C102CP"' \
  "http://localhost:8089/search/records?uri=384C102CP&resolve[]=[record_types, to_resolve]"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"H863392HG"' \
  "http://localhost:8089/search/records?uri=384C102CP&resolve[]=[record_types, to_resolve]"
  

```



__Endpoint__

```[:GET, :POST] /search/records ```


__Description__

Return a set of records by URI.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>uri</code></td>
        <td style="word-break: break-word;">
            The list of record URIs to fetch
            
        </td>
        <td>[String]</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            The list of result fields to resolve (if any)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- a JSON map of records



## Search across repositories



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"D24324P189"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"518510LHY"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"56XK567C"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"P76614O91"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"GTG829O"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"RXGC214"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BH386RX"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"YNR297K"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"980X614Q738"' \
  "http://localhost:8089/search/repositories?q=D24324P189&aq=["Example Missing"]&type=518510LHY&sort=56XK567C&facet=P76614O91&facet_mincount=1&filter=["Example Missing"]&filter_query=GTG829O&exclude=RXGC214&hl=true&root_record=BH386RX&dt=YNR297K&fields=980X614Q738"
  

```



__Endpoint__

```[:GET, :POST] /search/repositories ```


__Description__

Search across repositories.

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
</ul>
</aside>

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>q</code></td>
        <td style="word-break: break-word;">
            A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>aq</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>type</code></td>
        <td style="word-break: break-word;">
            The record type to search (defaults to all types if not specified)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>sort</code></td>
        <td style="word-break: break-word;">
            The attribute to sort and the direction e.g. &sort=title desc&...
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet</code></td>
        <td style="word-break: break-word;">
            The list of the fields to produce facets for
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet_mincount</code></td>
        <td style="word-break: break-word;">
            The minimum count for a facet field to be included in the response
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query to filter by
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter_query</code></td>
        <td style="word-break: break-word;">
            Search queries to be applied as a filter to the results.
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>exclude</code></td>
        <td style="word-break: break-word;">
            A list of document IDs that should be excluded from results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>hl</code></td>
        <td style="word-break: break-word;">
            Whether to use highlighting
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>root_record</code></td>
        <td style="word-break: break-word;">
            Search within a collection of records (defined by the record at the root of the tree)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>dt</code></td>
        <td style="word-break: break-word;">
            Format to return (JSON default)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>fields</code></td>
        <td style="word-break: break-word;">
            The list of fields to include in the results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- 



## Search across subjects



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"226X195670557"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"WD701NB"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"PX726JG"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"JLM647E"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"511G779NF"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"USJIJ"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"SXC543E"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"I275315ML"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"Q738454959539"' \
  "http://localhost:8089/search/subjects?q=226X195670557&aq=["Example Missing"]&type=WD701NB&sort=PX726JG&facet=JLM647E&facet_mincount=1&filter=["Example Missing"]&filter_query=511G779NF&exclude=USJIJ&hl=true&root_record=SXC543E&dt=I275315ML&fields=Q738454959539"
  

```



__Endpoint__

```[:GET, :POST] /search/subjects ```

<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Deprecated in favor of calling the general search endpoint with an  optional type parameter. For example: /repositories/:repo_id/search?type[]=subject</p>
  
</aside>

__Description__

Search across subjects.

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  


__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
</ul>
</aside>

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>q</code></td>
        <td style="word-break: break-word;">
            A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>aq</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>type</code></td>
        <td style="word-break: break-word;">
            The record type to search (defaults to all types if not specified)
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>sort</code></td>
        <td style="word-break: break-word;">
            The attribute to sort and the direction e.g. &sort=title desc&...
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet</code></td>
        <td style="word-break: break-word;">
            The list of the fields to produce facets for
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>facet_mincount</code></td>
        <td style="word-break: break-word;">
            The minimum count for a facet field to be included in the response
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter</code></td>
        <td style="word-break: break-word;">
            A json string containing the advanced query to filter by
            
        </td>
        <td>JSONModel(:advanced_query)</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>filter_query</code></td>
        <td style="word-break: break-word;">
            Search queries to be applied as a filter to the results.
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>exclude</code></td>
        <td style="word-break: break-word;">
            A list of document IDs that should be excluded from results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>hl</code></td>
        <td style="word-break: break-word;">
            Whether to use highlighting
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>root_record</code></td>
        <td style="word-break: break-word;">
            Search within a collection of records (defined by the record at the root of the tree)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>dt</code></td>
        <td style="word-break: break-word;">
            Format to return (JSON default)
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>fields</code></td>
        <td style="word-break: break-word;">
            The list of fields to include in the results
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- 



## Find the record given the slug, return id, repo_id, and table name



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/slug?slug=slug&controller=controller&action=action"

```



__Endpoint__

```[:GET] /slug ```


__Description__

Find the record given the slug, return id, repo_id, and table name.

      

__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>s</code></td>
        <td style="word-break: break-word;">
            u
            
        </td>
        <td>l</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>c</code></td>
        <td style="word-break: break-word;">
            n
            
        </td>
        <td>o</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>a</code></td>
        <td style="word-break: break-word;">
            t
            
        </td>
        <td>c</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- 



## Get a Location by ID




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/space_calculator/buildings"

```



__Endpoint__

```[:GET] /space_calculator/buildings ```


__Description__

Get a Location by ID.




__Returns__

  	200 -- Location building data as JSON



## Calculate how many containers will fit in locations for a given building



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/space_calculator/by_building?container_profile_uri=960O927S810&building=191R568271C&floor=YY34693L&room=211AFKU&area=RI649MF"

```



__Endpoint__

```[:GET] /space_calculator/by_building ```


__Description__

Calculate how many containers will fit in locations for a given building.

  
  
  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>container_profile_uri</code></td>
        <td style="word-break: break-word;">
            The uri of the container profile
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>building</code></td>
        <td style="word-break: break-word;">
            The building to check for space in
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>floor</code></td>
        <td style="word-break: break-word;">
            The floor to check for space in
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>room</code></td>
        <td style="word-break: break-word;">
            The room to check for space in
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>area</code></td>
        <td style="word-break: break-word;">
            The area to check for space in
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Calculation results



## Calculate how many containers will fit in a list of locations



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/space_calculator/by_location?container_profile_uri=17845380NR&location_uris=260882NKD"

```



__Endpoint__

```[:GET] /space_calculator/by_location ```


__Description__

Calculate how many containers will fit in a list of locations.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>container_profile_uri</code></td>
        <td style="word-break: break-word;">
            The uri of the container profile
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>location_uris</code></td>
        <td style="word-break: break-word;">
            A list of location uris to calculate space for
            
        </td>
        <td>[String]</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Calculation results



## Create a Subject



  
    
  

  
    
  
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION"       -d '{ "jsonmodel_type":"subject",
"external_ids":[],
"publish":true,
"is_slug_auto":true,
"used_within_repositories":[],
"used_within_published_repositories":[],
"terms":[{ "jsonmodel_type":"term",
"term":"Term 1",
"term_type":"topical",
"vocabulary":"/vocabularies/2"}],
"external_documents":[],
"vocabulary":"/vocabularies/3",
"authority_id":"http://www.example-18.com",
"scope_note":"440FVOO",
"source":"lcsh"}'         "http://localhost:8089/subjects"

```


```python
from asnake.aspace import ASpace
from asnake.jsonmodel import JM
# create a new subject
# minimum requirements:
# -  at least one Term object, with a term, a valid term_type, and  vocabulary (set to `/vocabularies/1')
# - a defined source (e.g.: ingest, lcsh) and vocabulary (set to `/vocabularies/1')
subj_json = JM.subject(source='ingest', vocabulary='/vocabularies/1' )
term = JM.term(term='Black lives matter movement', term_type='topical',vocabulary='/vocabularies/1' )
subj_json["terms"] = [term]
res = aspace.client.post('/subjects', json=subj_json)
subj_id = None
if res.status_code ==  200:
  subj_id = res.json()["id"]

```


__Endpoint__

```[:POST] /subjects ```


__Description__

Create a Subject.

  
  


__Accepts Payload of Type__

JSONModel(:subject)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## Get a list of Subjects




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/subjects?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/subjects?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/subjects?all_ids=true"

```



__Endpoint__

```[:GET] /subjects ```


__Description__

Get a list of Subjects.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>




__Returns__

  	200 -- [(:subject)]



## Update a Subject



  
    
  
  
    
  

  
    
  
  
    
  
  
  
  ```shell
  curl -H "X-ArchivesSpace-Session: $SESSION"         -d '{ "jsonmodel_type":"subject",
"external_ids":[],
"publish":true,
"is_slug_auto":true,
"used_within_repositories":[],
"used_within_published_repositories":[],
"terms":[{ "jsonmodel_type":"term",
"term":"Term 1",
"term_type":"topical",
"vocabulary":"/vocabularies/2"}],
"external_documents":[],
"vocabulary":"/vocabularies/3",
"authority_id":"http://www.example-18.com",
"scope_note":"440FVOO",
"source":"lcsh"}'         "http://localhost:8089/subjects/1"

```


```python
from asnake.aspace import ASpace
subj = aspace.subjects(1)
# test to be sure that you got something
if subj.__class__.__name__ == 'JSONModelObject':
  json_subj = subj.json()
  json_subj['source'] = 'lcsh'
  json_subj['authority_id'] = 'http://id.loc.gov/authorities/subjects/sh2016001442'  
  res = aspace.client.post(json_subj['uri'], json=json_subj)
  if res.status_code != 200:
    print(f'ERROR: {res.status_code}')

```


__Endpoint__

```[:POST] /subjects/:id ```


__Description__

Update a Subject.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:subject)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a Subject by ID



  
    
  

  
    
  
  
  ```shell
url -H "X-ArchivesSpace-Session: $SESSION"       "http://localhost:8089/subjects/1"

```


```python
from asnake.aspace import ASpace
subj = aspace.subjects(1)
# test to be sure that you got something
if subj.__class__.__name__ == 'JSONModelObject':
    json_subj = subj.json()
    print(f'Title: {json_subj["title"]}; Source: {json_subj["source"]}')
    if 'authority_id' in json_subj:
      print(f'Authority ID: {json_subj["authority_id"]}')
    else:
        print('Authority ID not defined')

```


__Endpoint__

```[:GET] /subjects/:id ```


__Description__

Get a Subject by ID.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:subject)



## Delete a Subject



  
    
  

  
    
  
  
  ```shell
curl -H "X-ArchivesSpace-Session: $SESSION"       -X DELETE       "http://localhost:8089/subjects/1"  

```


```python
from asnake.aspace import ASpace
res = aspace.client.delete("http://localhost:8089/subjects/1")

```


__Endpoint__

```[:DELETE] /subjects/:id ```


__Description__

Delete a Subject.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Get a list of Terms matching a prefix



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/terms?q=A238D789B"

```



__Endpoint__

```[:GET] /terms ```


__Description__

Get a list of Terms matching a prefix.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>q</code></td>
        <td style="word-break: break-word;">
            The prefix to match
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:term)]



## Get a stream of updated records



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/update-feed?last_sequence=1&resolve[]=[record_types, to_resolve]"

```



__Endpoint__

```[:GET] /update-feed ```


__Description__

Get a stream of updated records.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>last_sequence</code></td>
        <td style="word-break: break-word;">
            The last sequence number seen
            
        </td>
        <td>Integer</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>resolve</code></td>
        <td style="word-break: break-word;">
            A list of references to resolve and embed in the response
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- a list of records and sequence numbers



## Refresh the list of currently known edits



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/update_monitor"

```



__Endpoint__

```[:POST] /update_monitor ```


__Description__

Refresh the list of currently known edits.

  
  


__Accepts Payload of Type__

JSONModel(:active_edits)

__Returns__

  	200 -- A list of records, the user editing it and the lock version for each



## Create a local user



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_active_user":true,
"is_admin":false,
"username":"username_1",
"name":"Name Number 16"}' \
  "http://localhost:8089/users?password=857P2UQ&groups=764B69082K"

```



__Endpoint__

```[:POST] /users ```


__Description__

Create a local user.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>password</code></td>
        <td style="word-break: break-word;">
            The user's password
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>groups</code></td>
        <td style="word-break: break-word;">
            Array of groups URIs to assign the user to
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:user)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}



## Get a list of users




  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/users?page=1&page_size=10"
# return first 5 records in the Fibonacci sequence
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/users?id_set=1,2,3,5,8"
# return an array of all the ids
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/users?all_ids=true"

```



__Endpoint__

```[:GET] /users ```


__Description__

Get a list of users.



__Parameters__
<aside class="notice">
This endpoint is paginated. :page, :id_set, or :all_ids is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
  <li>Comma separated list id_set &ndash; A list of ids to request resolved objects ( Must be smaller than default page_size )</li>
  <li>Boolean all_ids &ndash; Return a list of all object ids</li>
</ul>
</aside>




__Returns__

  	200 -- [(:resource)]



## Get a user's details (including their current permissions)



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/users/1"

```



__Endpoint__

```[:GET] /users/:id ```


__Description__

Get a user's details (including their current permissions).

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The username id to fetch
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:user)



## Update a user's account



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_active_user":true,
"is_admin":false,
"username":"username_1",
"name":"Name Number 16"}' \
  "http://localhost:8089/users/1?password=BKE531J"

```



__Endpoint__

```[:POST] /users/:id ```


__Description__

Update a user's account.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>password</code></td>
        <td style="word-break: break-word;">
            The user's password
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:user)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Delete a user



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/users/1"

```



__Endpoint__

```[:DELETE] /users/:id ```


__Description__

Delete a user.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The user to delete
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- deleted



## Set a user to be activated



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/users/1/activate"

```



__Endpoint__

```[:GET] /users/:id/activate ```


__Description__

Set a user to be activated.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The username id to fetch
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:user)



## Set a user to be deactivated



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/users/1/deactivate"

```



__Endpoint__

```[:GET] /users/:id/deactivate ```


__Description__

Set a user to be deactivated.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The username id to fetch
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- (:user)



## Update a user's groups



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/users/1/groups?groups=XCBNR&remove_groups=true"

```



__Endpoint__

```[:POST] /users/:id/groups ```


__Description__

Update a user's groups.

  
  
  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>groups</code></td>
        <td style="word-break: break-word;">
            Array of groups URIs to assign the user to
            
        </td>
        <td>[String]</td>
        <td>true</td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>remove_groups</code></td>
        <td style="word-break: break-word;">
            Remove all groups from the user for the current repo_id if true
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>repo_id</code></td>
        <td style="word-break: break-word;">
            The Repository groups to clear
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}

  	400 -- {:error => (description of error)}



## Become a different user



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/users/1/become-user"

```



__Endpoint__

```[:POST] /users/:username/become-user ```


__Description__

Become a different user.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>username</code></td>
        <td style="word-break: break-word;">
            The username to become
            
        </td>
        <td>Username</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Accepted

  	404 -- User not found



## Log in



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/users/1/login?password=D43596X752&expiring=true"

```



__Endpoint__

```[:POST] /users/:username/login ```


__Description__

Log in.

  
  
  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>username</code></td>
        <td style="word-break: break-word;">
            Your username
            
        </td>
        <td>Username</td>
        <td></td>
      </tr>
    
        
          
        

        
        
      <tr>      
        <td><code>password</code></td>
        <td style="word-break: break-word;">
            Your password
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>expiring</code></td>
        <td style="word-break: break-word;">
            If true, the session will expire after 604800000 seconds of inactivity.  If false, it will  expire after 604800 seconds of inactivity.

NOTE: Previously this parameter would cause the created session to last forever, but this generally isn't what you want.  The parameter name is unfortunate, but we're keeping it for backward-compatibility.
            
        </td>
        <td>RESTHelpers::BooleanParam</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- Login accepted

  	403 -- Login failed



## Get a list of system users



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/users/complete?query=372TOUD"

```



__Endpoint__

```[:GET] /users/complete ```


__Description__

Get a list of system users.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>query</code></td>
        <td style="word-break: break-word;">
            A prefix to search for
            
        </td>
        <td>String</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- A list of usernames



## Get the currently logged in user




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/users/current-user"

```



__Endpoint__

```[:GET] /users/current-user ```


__Description__

Get the currently logged in user.




__Returns__

  	200 -- (:user)

  	404 -- Not logged in



## Get the ArchivesSpace application version




  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/version"

```



__Endpoint__

```[:GET] /version ```


__Description__

Get the ArchivesSpace application version.




__Returns__

  	200 -- ArchivesSpace (version)



## Create a Vocabulary



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"vocabulary",
"terms":[],
"name":"Vocabulary 5 - 2021-09-20 19:04:41 -0400",
"ref_id":"vocab_ref_5 - 2021-09-20 19:04:41 -0400"}' \
  "http://localhost:8089/vocabularies"

```



__Endpoint__

```[:POST] /vocabularies ```


__Description__

Create a Vocabulary.

  
  


__Accepts Payload of Type__

JSONModel(:vocabulary)

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}



## Get a list of Vocabularies



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/vocabularies?ref_id=KY268932E"

```



__Endpoint__

```[:GET] /vocabularies ```


__Description__

Get a list of Vocabularies.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
        
        
        
      <tr>      
        <td><code>ref_id</code></td>
        <td style="word-break: break-word;">
            An alternate, externally-created ID for the vocabulary
            
        </td>
        <td>String</td>
        <td>true</td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:vocabulary)]



## Update a Vocabulary



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"vocabulary",
"terms":[],
"name":"Vocabulary 5 - 2021-09-20 19:04:41 -0400",
"ref_id":"vocab_ref_5 - 2021-09-20 19:04:41 -0400"}' \
  "http://localhost:8089/vocabularies/1"

```



__Endpoint__

```[:POST] /vocabularies/:id ```


__Description__

Update a Vocabulary.

  
  
  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>

__Accepts Payload of Type__

JSONModel(:vocabulary)

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}



## Get a Vocabulary by ID



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/vocabularies/1"

```



__Endpoint__

```[:GET] /vocabularies/:id ```


__Description__

Get a Vocabulary by ID.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- OK



## Get a list of Terms for a Vocabulary



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/vocabularies/1/terms"

```



__Endpoint__

```[:GET] /vocabularies/:id/terms ```


__Description__

Get a list of Terms for a Vocabulary.

  
  


__Parameters__

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Parameter</th>
      <th style="width: 45%;">Description</th>
      <th style="width: 20%;">Type</th>
      <th style="width: 10%;">Optional?</th>
    </tr>
  </thead>
  <tbody>
    
        
          
        

        
        
      <tr>      
        <td><code>id</code></td>
        <td style="word-break: break-word;">
            The ID of the record
            
        </td>
        <td>Integer</td>
        <td></td>
      </tr>
    
  </tbody>
</table>


__Returns__

  	200 -- [(:term)]



# Routes by URI

<p>An index of routes available in the ArchivesSpace API, alphabetically by URI.</p>

<table>
  <thead>
    <tr>
      <th>Route</th> <th>Method(s)</th> <th>Description</th>
    </tr>
  </thead>
  <tbody>
    
      <tr>
        <td><a href="#create-a-corporate-entity-agent">/agents/corporate_entities</a></td>
        <td>POST</td>
        <td>Create a corporate entity agent</td>
      </tr>
    
      <tr>
        <td><a href="#list-all-corporate-entity-agents">/agents/corporate_entities</a></td>
        <td>GET</td>
        <td>List all corporate entity agents</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-corporate-entity-agent">/agents/corporate_entities/:id</a></td>
        <td>POST</td>
        <td>Update a corporate entity agent</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-corporate-entity-by-id">/agents/corporate_entities/:id</a></td>
        <td>GET</td>
        <td>Get a corporate entity by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-corporate-entity-agent">/agents/corporate_entities/:id</a></td>
        <td>DELETE</td>
        <td>Delete a corporate entity agent</td>
      </tr>
    
      <tr>
        <td><a href="#publish-a-corporate-entity-agent-and-all-its-sub-records">/agents/corporate_entities/:id/publish</a></td>
        <td>POST</td>
        <td>Publish a corporate entity agent and all its sub-records</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-family-agent">/agents/families</a></td>
        <td>POST</td>
        <td>Create a family agent</td>
      </tr>
    
      <tr>
        <td><a href="#list-all-family-agents">/agents/families</a></td>
        <td>GET</td>
        <td>List all family agents</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-family-agent">/agents/families/:id</a></td>
        <td>POST</td>
        <td>Update a family agent</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-family-by-id">/agents/families/:id</a></td>
        <td>GET</td>
        <td>Get a family by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-agent-family">/agents/families/:id</a></td>
        <td>DELETE</td>
        <td>Delete an agent family</td>
      </tr>
    
      <tr>
        <td><a href="#publish-a-family-agent-and-all-its-sub-records">/agents/families/:id/publish</a></td>
        <td>POST</td>
        <td>Publish a family agent and all its sub-records</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-person-agent">/agents/people</a></td>
        <td>POST</td>
        <td>Create a person agent</td>
      </tr>
    
      <tr>
        <td><a href="#list-all-person-agents">/agents/people</a></td>
        <td>GET</td>
        <td>List all person agents</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-person-agent">/agents/people/:id</a></td>
        <td>POST</td>
        <td>Update a person agent</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-person-by-id">/agents/people/:id</a></td>
        <td>GET</td>
        <td>Get a person by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-agent-person">/agents/people/:id</a></td>
        <td>DELETE</td>
        <td>Delete an agent person</td>
      </tr>
    
      <tr>
        <td><a href="#publish-an-agent-person-and-all-its-sub-records">/agents/people/:id/publish</a></td>
        <td>POST</td>
        <td>Publish an agent person and all its sub-records</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-software-agent">/agents/software</a></td>
        <td>POST</td>
        <td>Create a software agent</td>
      </tr>
    
      <tr>
        <td><a href="#list-all-software-agents">/agents/software</a></td>
        <td>GET</td>
        <td>List all software agents</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-software-agent">/agents/software/:id</a></td>
        <td>POST</td>
        <td>Update a software agent</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-software-agent-by-id">/agents/software/:id</a></td>
        <td>GET</td>
        <td>Get a software agent by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-software-agent">/agents/software/:id</a></td>
        <td>DELETE</td>
        <td>Delete a software agent</td>
      </tr>
    
      <tr>
        <td><a href="#publish-a-software-agent-and-all-its-sub-records">/agents/software/:id/publish</a></td>
        <td>POST</td>
        <td>Publish a software agent and all its sub-records</td>
      </tr>
    
      <tr>
        <td><a href="#redirect-to-resource-identified-by-ark-name">/ark*/:naan/:id</a></td>
        <td>GET</td>
        <td>Redirect to resource identified by ARK Name</td>
      </tr>
    
      <tr>
        <td><a href="#carry-out-delete-requests-against-a-list-of-records">/batch_delete</a></td>
        <td>POST</td>
        <td>Carry out delete requests against a list of records</td>
      </tr>
    
      <tr>
        <td><a href="#list-records-by-their-external-id-s">/by-external-id</a></td>
        <td>GET</td>
        <td>List records by their external ID(s)</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-enumeration-value">/config/enumeration_values/:enum_val_id</a></td>
        <td>GET</td>
        <td>Get an Enumeration Value</td>
      </tr>
    
      <tr>
        <td><a href="#update-an-enumeration-value">/config/enumeration_values/:enum_val_id</a></td>
        <td>POST</td>
        <td>Update an enumeration value</td>
      </tr>
    
      <tr>
        <td><a href="#update-the-position-of-an-ennumeration-value">/config/enumeration_values/:enum_val_id/position</a></td>
        <td>POST</td>
        <td>Update the position of an ennumeration value</td>
      </tr>
    
      <tr>
        <td><a href="#suppress-this-value">/config/enumeration_values/:enum_val_id/suppressed</a></td>
        <td>POST</td>
        <td>Suppress this value</td>
      </tr>
    
      <tr>
        <td><a href="#list-all-defined-enumerations">/config/enumerations</a></td>
        <td>GET</td>
        <td>List all defined enumerations</td>
      </tr>
    
      <tr>
        <td><a href="#create-an-enumeration">/config/enumerations</a></td>
        <td>POST</td>
        <td>Create an enumeration</td>
      </tr>
    
      <tr>
        <td><a href="#update-an-enumeration">/config/enumerations/:enum_id</a></td>
        <td>POST</td>
        <td>Update an enumeration</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-enumeration">/config/enumerations/:enum_id</a></td>
        <td>GET</td>
        <td>Get an Enumeration</td>
      </tr>
    
      <tr>
        <td><a href="#list-all-defined-enumerations-as-a-csv">/config/enumerations/csv</a></td>
        <td>GET</td>
        <td>List all defined enumerations as a csv</td>
      </tr>
    
      <tr>
        <td><a href="#migrate-all-records-from-one-value-to-another">/config/enumerations/migration</a></td>
        <td>POST</td>
        <td>Migrate all records from one value to another</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-enumeration-by-name">/config/enumerations/names/:enum_name</a></td>
        <td>GET</td>
        <td>Get an Enumeration by Name</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-container-profile">/container_profiles</a></td>
        <td>POST</td>
        <td>Create a Container_Profile</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-container-profiles">/container_profiles</a></td>
        <td>GET</td>
        <td>Get a list of Container Profiles</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-container-profile">/container_profiles/:id</a></td>
        <td>POST</td>
        <td>Update a Container Profile</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-container-profile-by-id">/container_profiles/:id</a></td>
        <td>GET</td>
        <td>Get a Container Profile by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-container-profile">/container_profiles/:id</a></td>
        <td>DELETE</td>
        <td>Delete an Container Profile</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-global-preferences-records-for-the-current-user">/current_global_preferences</a></td>
        <td>GET</td>
        <td>Get the global Preferences records for the current user.</td>
      </tr>
    
      <tr>
        <td><a href="#calculate-the-dates-of-an-archival-object-tree">/date_calculator</a></td>
        <td>GET</td>
        <td>Calculate the dates of an archival object tree</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-stream-of-deleted-records">/delete-feed</a></td>
        <td>GET</td>
        <td>Get a stream of deleted records</td>
      </tr>
    
      <tr>
        <td><a href="#calculate-the-extent-of-an-archival-object-tree">/extent_calculator</a></td>
        <td>GET</td>
        <td>Calculate the extent of an archival object tree</td>
      </tr>
    
      <tr>
        <td><a href="#list-all-supported-job-types">/job_types</a></td>
        <td>GET</td>
        <td>List all supported job types</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-location-profile">/location_profiles</a></td>
        <td>POST</td>
        <td>Create a Location_Profile</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-location-profiles">/location_profiles</a></td>
        <td>GET</td>
        <td>Get a list of Location Profiles</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-location-profile">/location_profiles/:id</a></td>
        <td>POST</td>
        <td>Update a Location Profile</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-location-profile-by-id">/location_profiles/:id</a></td>
        <td>GET</td>
        <td>Get a Location Profile by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-location-profile">/location_profiles/:id</a></td>
        <td>DELETE</td>
        <td>Delete an Location Profile</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-location">/locations</a></td>
        <td>POST</td>
        <td>Create a Location</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-locations">/locations</a></td>
        <td>GET</td>
        <td>Get a list of locations</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-location">/locations/:id</a></td>
        <td>POST</td>
        <td>Update a Location</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-location-by-id">/locations/:id</a></td>
        <td>GET</td>
        <td>Get a Location by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-location">/locations/:id</a></td>
        <td>DELETE</td>
        <td>Delete a Location</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-batch-of-locations">/locations/batch</a></td>
        <td>POST</td>
        <td>Create a Batch of Locations</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-location">/locations/batch_update</a></td>
        <td>POST</td>
        <td>Update a Location</td>
      </tr>
    
      <tr>
        <td><a href="#log-out-the-current-session">/logout</a></td>
        <td>POST</td>
        <td>Log out the current session</td>
      </tr>
    
      <tr>
        <td><a href="#carry-out-a-merge-request-against-agent-records">/merge_requests/agent</a></td>
        <td>POST</td>
        <td>Carry out a merge request against Agent records</td>
      </tr>
    
      <tr>
        <td><a href="#carry-out-a-detailed-merge-request-against-agent-records">/merge_requests/agent_detail</a></td>
        <td>POST</td>
        <td>Carry out a detailed merge request against Agent records</td>
      </tr>
    
      <tr>
        <td><a href="#carry-out-a-merge-request-against-container-profile-records">/merge_requests/container_profile</a></td>
        <td>POST</td>
        <td>Carry out a merge request against Container Profile records</td>
      </tr>
    
      <tr>
        <td><a href="#carry-out-a-merge-request-against-digital-object-records">/merge_requests/digital_object</a></td>
        <td>POST</td>
        <td>Carry out a merge request against Digital_Object records</td>
      </tr>
    
      <tr>
        <td><a href="#carry-out-a-merge-request-against-resource-records">/merge_requests/resource</a></td>
        <td>POST</td>
        <td>Carry out a merge request against Resource records</td>
      </tr>
    
      <tr>
        <td><a href="#carry-out-a-merge-request-against-subject-records">/merge_requests/subject</a></td>
        <td>POST</td>
        <td>Carry out a merge request against Subject records</td>
      </tr>
    
      <tr>
        <td><a href="#carry-out-a-merge-request-against-top-container-records">/merge_requests/top_container</a></td>
        <td>POST</td>
        <td>Carry out a merge request against Top Container records</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-stream-of-notifications">/notifications</a></td>
        <td>GET</td>
        <td>Get a stream of notifications</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-permissions">/permissions</a></td>
        <td>GET</td>
        <td>Get a list of Permissions</td>
      </tr>
    
      <tr>
        <td><a href="#list-all-reports">/reports</a></td>
        <td>GET</td>
        <td>List all reports</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-availiable-options-for-custom-reports">/reports/custom_data</a></td>
        <td>GET</td>
        <td>Get a list of availiable options for custom reports</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-static-asset-for-a-report">/reports/static/*</a></td>
        <td>GET</td>
        <td>Get a static asset for a report</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-repository">/repositories</a></td>
        <td>POST</td>
        <td>Create a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-repositories">/repositories</a></td>
        <td>GET</td>
        <td>Get a list of Repositories</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-repository">/repositories/:id</a></td>
        <td>POST</td>
        <td>Update a repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-repository-by-id">/repositories/:id</a></td>
        <td>GET</td>
        <td>Get a Repository by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-repository">/repositories/:repo_id</a></td>
        <td>DELETE</td>
        <td>Delete a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#create-an-accession">/repositories/:repo_id/accessions</a></td>
        <td>POST</td>
        <td>Create an Accession</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-accessions-for-a-repository">/repositories/:repo_id/accessions</a></td>
        <td>GET</td>
        <td>Get a list of Accessions for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#update-an-accession">/repositories/:repo_id/accessions/:id</a></td>
        <td>POST</td>
        <td>Update an Accession</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-accession-by-id">/repositories/:repo_id/accessions/:id</a></td>
        <td>GET</td>
        <td>Get an Accession by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-accession">/repositories/:repo_id/accessions/:id</a></td>
        <td>DELETE</td>
        <td>Delete an Accession</td>
      </tr>
    
      <tr>
        <td><a href="#suppress-this-record">/repositories/:repo_id/accessions/:id/suppressed</a></td>
        <td>POST</td>
        <td>Suppress this record</td>
      </tr>
    
      <tr>
        <td><a href="#get-top-containers-linked-to-an-accession">/repositories/:repo_id/accessions/:id/top_containers</a></td>
        <td>GET</td>
        <td>Get Top Containers linked to an Accession</td>
      </tr>
    
      <tr>
        <td><a href="#transfer-this-record-to-a-different-repository">/repositories/:repo_id/accessions/:id/transfer</a></td>
        <td>POST</td>
        <td>Transfer this record to a different repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-an-marc-auth-export-of-a-corporate-entity">/repositories/:repo_id/agents/corporate_entities/marc21/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for an MARC Auth export of a corporate entity</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-marc-auth-representation-of-a-corporate-entity">/repositories/:repo_id/agents/corporate_entities/marc21/:id.xml</a></td>
        <td>GET</td>
        <td>Get a MARC Auth representation of a Corporate Entity</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-an-marc-auth-export-of-a-family">/repositories/:repo_id/agents/families/marc21/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for an MARC Auth export of a family</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-marc-auth-representation-of-a-family">/repositories/:repo_id/agents/families/marc21/:id.xml</a></td>
        <td>GET</td>
        <td>Get an MARC Auth representation of a Family</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-an-marc-auth-export-of-a-person">/repositories/:repo_id/agents/people/marc21/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for an MARC Auth export of a person</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-marc-auth-representation-of-an-person">/repositories/:repo_id/agents/people/marc21/:id.xml</a></td>
        <td>GET</td>
        <td>Get an MARC Auth representation of an Person</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-an-eac-cpf-export-of-a-corporate-entity">/repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for an EAC-CPF export of a corporate entity</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-eac-cpf-representation-of-a-corporate-entity">/repositories/:repo_id/archival_contexts/corporate_entities/:id.xml</a></td>
        <td>GET</td>
        <td>Get an EAC-CPF representation of a Corporate Entity</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-an-eac-cpf-export-of-a-family">/repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for an EAC-CPF export of a family</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-eac-cpf-representation-of-a-family">/repositories/:repo_id/archival_contexts/families/:id.xml</a></td>
        <td>GET</td>
        <td>Get an EAC-CPF representation of a Family</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-an-eac-cpf-export-of-a-person">/repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for an EAC-CPF export of a person</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-eac-cpf-representation-of-an-agent">/repositories/:repo_id/archival_contexts/people/:id.xml</a></td>
        <td>GET</td>
        <td>Get an EAC-CPF representation of an Agent</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-an-eac-cpf-export-of-a-software">/repositories/:repo_id/archival_contexts/softwares/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for an EAC-CPF export of a software</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-eac-cpf-representation-of-a-software-agent">/repositories/:repo_id/archival_contexts/softwares/:id.xml</a></td>
        <td>GET</td>
        <td>Get an EAC-CPF representation of a Software agent</td>
      </tr>
    
      <tr>
        <td><a href="#create-an-archival-object">/repositories/:repo_id/archival_objects</a></td>
        <td>POST</td>
        <td>Create an Archival Object</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-archival-objects-for-a-repository">/repositories/:repo_id/archival_objects</a></td>
        <td>GET</td>
        <td>Get a list of Archival Objects for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#update-an-archival-object">/repositories/:repo_id/archival_objects/:id</a></td>
        <td>POST</td>
        <td>Update an Archival Object</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-archival-object-by-id">/repositories/:repo_id/archival_objects/:id</a></td>
        <td>GET</td>
        <td>Get an Archival Object by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-archival-object">/repositories/:repo_id/archival_objects/:id</a></td>
        <td>DELETE</td>
        <td>Delete an Archival Object</td>
      </tr>
    
      <tr>
        <td><a href="#move-existing-archival-objects-to-become-children-of-an-archival-object">/repositories/:repo_id/archival_objects/:id/accept_children</a></td>
        <td>POST</td>
        <td>Move existing Archival Objects to become children of an Archival Object</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-children-of-an-archival-object">/repositories/:repo_id/archival_objects/:id/children</a></td>
        <td>GET</td>
        <td>Get the children of an Archival Object</td>
      </tr>
    
      <tr>
        <td><a href="#batch-create-several-archival-objects-as-children-of-an-existing-archival-object">/repositories/:repo_id/archival_objects/:id/children</a></td>
        <td>POST</td>
        <td>Batch create several Archival Objects as children of an existing Archival Object</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-record-types-in-the-graph-of-an-archival-object">/repositories/:repo_id/archival_objects/:id/models_in_graph</a></td>
        <td>GET</td>
        <td>Get a list of record types in the graph of an archival object</td>
      </tr>
    
      <tr>
        <td><a href="#set-the-parent-position-of-an-archival-object-in-a-tree">/repositories/:repo_id/archival_objects/:id/parent</a></td>
        <td>POST</td>
        <td>Set the parent/position of an Archival Object in a tree</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-previous-record-in-the-tree-for-an-archival-object">/repositories/:repo_id/archival_objects/:id/previous</a></td>
        <td>GET</td>
        <td>Get the previous record in the tree for an Archival Object</td>
      </tr>
    
      <tr>
        <td><a href="#publish-an-archival-object-and-all-its-sub-records-and-components">/repositories/:repo_id/archival_objects/:id/publish</a></td>
        <td>POST</td>
        <td>Publish an Archival Object and all its sub-records and components</td>
      </tr>
    
      <tr>
        <td><a href="#suppress-this-record">/repositories/:repo_id/archival_objects/:id/suppressed</a></td>
        <td>POST</td>
        <td>Suppress this record</td>
      </tr>
    
      <tr>
        <td><a href="#unpublish-an-archival-object-and-all-its-sub-records-and-components">/repositories/:repo_id/archival_objects/:id/unpublish</a></td>
        <td>POST</td>
        <td>Unpublish an Archival Object and all its sub-records and components</td>
      </tr>
    
      <tr>
        <td><a href="#update-this-repository-s-assessment-attribute-definitions">/repositories/:repo_id/assessment_attribute_definitions</a></td>
        <td>POST</td>
        <td>Update this repository's assessment attribute definitions</td>
      </tr>
    
      <tr>
        <td><a href="#get-this-repository-s-assessment-attribute-definitions">/repositories/:repo_id/assessment_attribute_definitions</a></td>
        <td>GET</td>
        <td>Get this repository's assessment attribute definitions</td>
      </tr>
    
      <tr>
        <td><a href="#create-an-assessment">/repositories/:repo_id/assessments</a></td>
        <td>POST</td>
        <td>Create an Assessment</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-assessments-for-a-repository">/repositories/:repo_id/assessments</a></td>
        <td>GET</td>
        <td>Get a list of Assessments for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#update-an-assessment">/repositories/:repo_id/assessments/:id</a></td>
        <td>POST</td>
        <td>Update an Assessment</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-assessment-by-id">/repositories/:repo_id/assessments/:id</a></td>
        <td>GET</td>
        <td>Get an Assessment by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-assessment">/repositories/:repo_id/assessments/:id</a></td>
        <td>DELETE</td>
        <td>Delete an Assessment</td>
      </tr>
    
      <tr>
        <td><a href="#import-a-batch-of-records">/repositories/:repo_id/batch_imports</a></td>
        <td>POST</td>
        <td>Import a batch of records</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-classification-term">/repositories/:repo_id/classification_terms</a></td>
        <td>POST</td>
        <td>Create a Classification Term</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-classification-terms-for-a-repository">/repositories/:repo_id/classification_terms</a></td>
        <td>GET</td>
        <td>Get a list of Classification Terms for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-classification-term">/repositories/:repo_id/classification_terms/:id</a></td>
        <td>POST</td>
        <td>Update a Classification Term</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-classification-term-by-id">/repositories/:repo_id/classification_terms/:id</a></td>
        <td>GET</td>
        <td>Get a Classification Term by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-classification-term">/repositories/:repo_id/classification_terms/:id</a></td>
        <td>DELETE</td>
        <td>Delete a Classification Term</td>
      </tr>
    
      <tr>
        <td><a href="#move-existing-classification-terms-to-become-children-of-another-classification-term">/repositories/:repo_id/classification_terms/:id/accept_children</a></td>
        <td>POST</td>
        <td>Move existing Classification Terms to become children of another Classification Term</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-children-of-a-classification-term">/repositories/:repo_id/classification_terms/:id/children</a></td>
        <td>GET</td>
        <td>Get the children of a Classification Term</td>
      </tr>
    
      <tr>
        <td><a href="#set-the-parent-position-of-a-classification-term-in-a-tree">/repositories/:repo_id/classification_terms/:id/parent</a></td>
        <td>POST</td>
        <td>Set the parent/position of a Classification Term in a tree</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-classification">/repositories/:repo_id/classifications</a></td>
        <td>POST</td>
        <td>Create a Classification</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-classifications-for-a-repository">/repositories/:repo_id/classifications</a></td>
        <td>GET</td>
        <td>Get a list of Classifications for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-classification">/repositories/:repo_id/classifications/:id</a></td>
        <td>GET</td>
        <td>Get a Classification</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-classification">/repositories/:repo_id/classifications/:id</a></td>
        <td>POST</td>
        <td>Update a Classification</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-classification">/repositories/:repo_id/classifications/:id</a></td>
        <td>DELETE</td>
        <td>Delete a Classification</td>
      </tr>
    
      <tr>
        <td><a href="#move-existing-classification-terms-to-become-children-of-a-classification">/repositories/:repo_id/classifications/:id/accept_children</a></td>
        <td>POST</td>
        <td>Move existing Classification Terms to become children of a Classification</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-classification-tree">/repositories/:repo_id/classifications/:id/tree</a></td>
        <td>GET</td>
        <td>Get a Classification tree</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-tree-information-for-an-classification-term-record-within-a-tree">/repositories/:repo_id/classifications/:id/tree/node</a></td>
        <td>GET</td>
        <td>Fetch tree information for an Classification Term record within a tree</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-tree-path-from-the-root-record-to-classification-terms">/repositories/:repo_id/classifications/:id/tree/node_from_root</a></td>
        <td>GET</td>
        <td>Fetch tree path from the root record to Classification Terms</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-tree-information-for-the-top-level-classification-record">/repositories/:repo_id/classifications/:id/tree/root</a></td>
        <td>GET</td>
        <td>Fetch tree information for the top-level classification record</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-the-record-slice-for-a-given-tree-waypoint">/repositories/:repo_id/classifications/:id/tree/waypoint</a></td>
        <td>GET</td>
        <td>Fetch the record slice for a given tree waypoint</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-collection-management-record-by-id">/repositories/:repo_id/collection_management/:id</a></td>
        <td>GET</td>
        <td>Get a Collection Management Record by ID</td>
      </tr>
    
      <tr>
        <td><a href="#transfer-components-from-one-resource-to-another">/repositories/:repo_id/component_transfers</a></td>
        <td>POST</td>
        <td>Transfer components from one resource to another</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-preferences-records-for-the-current-repository-and-user">/repositories/:repo_id/current_preferences</a></td>
        <td>GET</td>
        <td>Get the Preferences records for the current repository and user.</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-custom-report-template">/repositories/:repo_id/custom_report_templates</a></td>
        <td>POST</td>
        <td>Create a Custom Report Template</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-custom-report-templates">/repositories/:repo_id/custom_report_templates</a></td>
        <td>GET</td>
        <td>Get a list of Custom Report Templates</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-customreporttemplate">/repositories/:repo_id/custom_report_templates/:id</a></td>
        <td>POST</td>
        <td>Update a CustomReportTemplate</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-custom-report-template-by-id">/repositories/:repo_id/custom_report_templates/:id</a></td>
        <td>GET</td>
        <td>Get a Custom Report Template by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-custom-report-template">/repositories/:repo_id/custom_report_templates/:id</a></td>
        <td>DELETE</td>
        <td>Delete an Custom Report Template</td>
      </tr>
    
      <tr>
        <td><a href="#save-defaults-for-a-record-type">/repositories/:repo_id/default_values/:record_type</a></td>
        <td>POST</td>
        <td>Save defaults for a record type</td>
      </tr>
    
      <tr>
        <td><a href="#get-default-values-for-a-record-type">/repositories/:repo_id/default_values/:record_type</a></td>
        <td>GET</td>
        <td>Get default values for a record type</td>
      </tr>
    
      <tr>
        <td><a href="#create-an-digital-object-component">/repositories/:repo_id/digital_object_components</a></td>
        <td>POST</td>
        <td>Create an Digital Object Component</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-digital-object-components-for-a-repository">/repositories/:repo_id/digital_object_components</a></td>
        <td>GET</td>
        <td>Get a list of Digital Object Components for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#update-an-digital-object-component">/repositories/:repo_id/digital_object_components/:id</a></td>
        <td>POST</td>
        <td>Update an Digital Object Component</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-digital-object-component-by-id">/repositories/:repo_id/digital_object_components/:id</a></td>
        <td>GET</td>
        <td>Get an Digital Object Component by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-digital-object-component">/repositories/:repo_id/digital_object_components/:id</a></td>
        <td>DELETE</td>
        <td>Delete a Digital Object Component</td>
      </tr>
    
      <tr>
        <td><a href="#move-existing-digital-object-components-to-become-children-of-a-digital-object-component">/repositories/:repo_id/digital_object_components/:id/accept_children</a></td>
        <td>POST</td>
        <td>Move existing Digital Object Components to become children of a Digital Object Component</td>
      </tr>
    
      <tr>
        <td><a href="#batch-create-several-digital-object-components-as-children-of-an-existing-digital-object-component">/repositories/:repo_id/digital_object_components/:id/children</a></td>
        <td>POST</td>
        <td>Batch create several Digital Object Components as children of an existing Digital Object Component</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-children-of-an-digital-object-component">/repositories/:repo_id/digital_object_components/:id/children</a></td>
        <td>GET</td>
        <td>Get the children of an Digital Object Component</td>
      </tr>
    
      <tr>
        <td><a href="#set-the-parent-position-of-an-digital-object-component-in-a-tree">/repositories/:repo_id/digital_object_components/:id/parent</a></td>
        <td>POST</td>
        <td>Set the parent/position of an Digital Object Component in a tree</td>
      </tr>
    
      <tr>
        <td><a href="#suppress-this-record">/repositories/:repo_id/digital_object_components/:id/suppressed</a></td>
        <td>POST</td>
        <td>Suppress this record</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-digital-object">/repositories/:repo_id/digital_objects</a></td>
        <td>POST</td>
        <td>Create a Digital Object</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-digital-objects-for-a-repository">/repositories/:repo_id/digital_objects</a></td>
        <td>GET</td>
        <td>Get a list of Digital Objects for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-digital-object">/repositories/:repo_id/digital_objects/:id</a></td>
        <td>GET</td>
        <td>Get a Digital Object</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-digital-object">/repositories/:repo_id/digital_objects/:id</a></td>
        <td>POST</td>
        <td>Update a Digital Object</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-digital-object">/repositories/:repo_id/digital_objects/:id</a></td>
        <td>DELETE</td>
        <td>Delete a Digital Object</td>
      </tr>
    
      <tr>
        <td><a href="#move-existing-digital-object-components-to-become-children-of-a-digital-object">/repositories/:repo_id/digital_objects/:id/accept_children</a></td>
        <td>POST</td>
        <td>Move existing Digital Object components to become children of a Digital Object</td>
      </tr>
    
      <tr>
        <td><a href="#batch-create-several-digital-object-components-as-children-of-an-existing-digital-object">/repositories/:repo_id/digital_objects/:id/children</a></td>
        <td>POST</td>
        <td>Batch create several Digital Object Components as children of an existing Digital Object</td>
      </tr>
    
      <tr>
        <td><a href="#publish-a-digital-object-and-all-its-sub-records-and-components">/repositories/:repo_id/digital_objects/:id/publish</a></td>
        <td>POST</td>
        <td>Publish a digital object and all its sub-records and components</td>
      </tr>
    
      <tr>
        <td><a href="#suppress-this-record">/repositories/:repo_id/digital_objects/:id/suppressed</a></td>
        <td>POST</td>
        <td>Suppress this record</td>
      </tr>
    
      <tr>
        <td><a href="#transfer-this-record-to-a-different-repository">/repositories/:repo_id/digital_objects/:id/transfer</a></td>
        <td>POST</td>
        <td>Transfer this record to a different repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-digital-object-tree">/repositories/:repo_id/digital_objects/:id/tree</a></td>
        <td>GET</td>
        <td>Get a Digital Object tree</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-tree-information-for-an-digital-object-component-record-within-a-tree">/repositories/:repo_id/digital_objects/:id/tree/node</a></td>
        <td>GET</td>
        <td>Fetch tree information for an Digital Object Component record within a tree</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-tree-paths-from-the-root-record-to-digital-object-components">/repositories/:repo_id/digital_objects/:id/tree/node_from_root</a></td>
        <td>GET</td>
        <td>Fetch tree paths from the root record to Digital Object Components</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-tree-information-for-the-top-level-digital-object-record">/repositories/:repo_id/digital_objects/:id/tree/root</a></td>
        <td>GET</td>
        <td>Fetch tree information for the top-level digital object record</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-the-record-slice-for-a-given-tree-waypoint">/repositories/:repo_id/digital_objects/:id/tree/waypoint</a></td>
        <td>GET</td>
        <td>Fetch the record slice for a given tree waypoint</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-a-dublin-core-export">/repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for a Dublin Core export</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-dublin-core-representation-of-a-digital-object">/repositories/:repo_id/digital_objects/dublin_core/:id.xml</a></td>
        <td>GET</td>
        <td>Get a Dublin Core representation of a Digital Object</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-a-mets-export">/repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for a METS export</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-mets-representation-of-a-digital-object">/repositories/:repo_id/digital_objects/mets/:id.xml</a></td>
        <td>GET</td>
        <td>Get a METS representation of a Digital Object</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-a-mods-export">/repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for a MODS export</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-mods-representation-of-a-digital-object">/repositories/:repo_id/digital_objects/mods/:id.xml</a></td>
        <td>GET</td>
        <td>Get a MODS representation of a Digital Object </td>
      </tr>
    
      <tr>
        <td><a href="#create-an-event">/repositories/:repo_id/events</a></td>
        <td>POST</td>
        <td>Create an Event</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-events-for-a-repository">/repositories/:repo_id/events</a></td>
        <td>GET</td>
        <td>Get a list of Events for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#update-an-event">/repositories/:repo_id/events/:id</a></td>
        <td>POST</td>
        <td>Update an Event</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-event-by-id">/repositories/:repo_id/events/:id</a></td>
        <td>GET</td>
        <td>Get an Event by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-event-record">/repositories/:repo_id/events/:id</a></td>
        <td>DELETE</td>
        <td>Delete an event record</td>
      </tr>
    
      <tr>
        <td><a href="#suppress-this-record-from-non-managers">/repositories/:repo_id/events/:id/suppressed</a></td>
        <td>POST</td>
        <td>Suppress this record from non-managers</td>
      </tr>
    
      <tr>
        <td><a href="#find-archival-objects-by-ref-id-or-component-id">/repositories/:repo_id/find_by_id/archival_objects</a></td>
        <td>GET</td>
        <td>Find Archival Objects by ref_id or component_id</td>
      </tr>
    
      <tr>
        <td><a href="#find-digital-object-components-by-component-id">/repositories/:repo_id/find_by_id/digital_object_components</a></td>
        <td>GET</td>
        <td>Find Digital Object Components by component_id</td>
      </tr>
    
      <tr>
        <td><a href="#find-digital-objects-by-digital-object-id">/repositories/:repo_id/find_by_id/digital_objects</a></td>
        <td>GET</td>
        <td>Find Digital Objects by digital_object_id</td>
      </tr>
    
      <tr>
        <td><a href="#find-resources-by-their-identifiers">/repositories/:repo_id/find_by_id/resources</a></td>
        <td>GET</td>
        <td>Find Resources by their identifiers</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-group-within-a-repository">/repositories/:repo_id/groups</a></td>
        <td>POST</td>
        <td>Create a group within a repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-groups-for-a-repository">/repositories/:repo_id/groups</a></td>
        <td>GET</td>
        <td>Get a list of groups for a repository</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-group">/repositories/:repo_id/groups/:id</a></td>
        <td>POST</td>
        <td>Update a group</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-group-by-id">/repositories/:repo_id/groups/:id</a></td>
        <td>GET</td>
        <td>Get a group by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-group-by-id">/repositories/:repo_id/groups/:id</a></td>
        <td>DELETE</td>
        <td>Delete a group by ID</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-new-job">/repositories/:repo_id/jobs</a></td>
        <td>POST</td>
        <td>Create a new job</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-jobs-for-a-repository">/repositories/:repo_id/jobs</a></td>
        <td>GET</td>
        <td>Get a list of Jobs for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-job">/repositories/:repo_id/jobs/:id</a></td>
        <td>DELETE</td>
        <td>Delete a Job</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-job-by-id">/repositories/:repo_id/jobs/:id</a></td>
        <td>GET</td>
        <td>Get a Job by ID</td>
      </tr>
    
      <tr>
        <td><a href="#cancel-a-job">/repositories/:repo_id/jobs/:id/cancel</a></td>
        <td>POST</td>
        <td>Cancel a Job</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-job-s-log-by-id">/repositories/:repo_id/jobs/:id/log</a></td>
        <td>GET</td>
        <td>Get a Job's log by ID</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-job-s-output-files-by-id">/repositories/:repo_id/jobs/:id/output_files</a></td>
        <td>GET</td>
        <td>Get a list of Job's output files by ID</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-job-s-output-file-by-id">/repositories/:repo_id/jobs/:id/output_files/:file_id</a></td>
        <td>GET</td>
        <td>Get a Job's output file by ID</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-job-s-list-of-created-uris">/repositories/:repo_id/jobs/:id/records</a></td>
        <td>GET</td>
        <td>Get a Job's list of created URIs</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-all-active-jobs-for-a-repository">/repositories/:repo_id/jobs/active</a></td>
        <td>GET</td>
        <td>Get a list of all active Jobs for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-all-archived-jobs-for-a-repository">/repositories/:repo_id/jobs/archived</a></td>
        <td>GET</td>
        <td>Get a list of all archived Jobs for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#list-all-supported-import-job-types">/repositories/:repo_id/jobs/import_types</a></td>
        <td>GET</td>
        <td>List all supported import job types</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-new-job-and-post-input-files">/repositories/:repo_id/jobs_with_files</a></td>
        <td>POST</td>
        <td>Create a new job and post input files</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-preferences-record">/repositories/:repo_id/preferences</a></td>
        <td>POST</td>
        <td>Create a Preferences record</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-preferences-for-a-repository-and-optionally-a-user">/repositories/:repo_id/preferences</a></td>
        <td>GET</td>
        <td>Get a list of Preferences for a Repository and optionally a user</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-preferences-record">/repositories/:repo_id/preferences/:id</a></td>
        <td>GET</td>
        <td>Get a Preferences record</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-preferences-record">/repositories/:repo_id/preferences/:id</a></td>
        <td>POST</td>
        <td>Update a Preferences record</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-preferences-record">/repositories/:repo_id/preferences/:id</a></td>
        <td>DELETE</td>
        <td>Delete a Preferences record</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-default-set-of-preferences-for-a-repository-and-optionally-a-user">/repositories/:repo_id/preferences/defaults</a></td>
        <td>GET</td>
        <td>Get the default set of Preferences for a Repository and optionally a user</td>
      </tr>
    
      <tr>
        <td><a href="#create-an-rde-template">/repositories/:repo_id/rde_templates</a></td>
        <td>POST</td>
        <td>Create an RDE template</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-rde-templates">/repositories/:repo_id/rde_templates</a></td>
        <td>GET</td>
        <td>Get a list of RDE Templates</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-rde-template-record">/repositories/:repo_id/rde_templates/:id</a></td>
        <td>GET</td>
        <td>Get an RDE template record</td>
      </tr>
    
      <tr>
        <td><a href="#delete-an-rde-template">/repositories/:repo_id/rde_templates/:id</a></td>
        <td>DELETE</td>
        <td>Delete an RDE Template</td>
      </tr>
    
      <tr>
        <td><a href="#require-fields-for-a-record-type">/repositories/:repo_id/required_fields/:record_type</a></td>
        <td>POST</td>
        <td>Require fields for a record type</td>
      </tr>
    
      <tr>
        <td><a href="#get-required-fields-for-a-record-type">/repositories/:repo_id/required_fields/:record_type</a></td>
        <td>GET</td>
        <td>Get required fields for a record type</td>
      </tr>
    
      <tr>
        <td><a href="#get-export-metadata-for-a-resource-description">/repositories/:repo_id/resource_descriptions/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get export metadata for a Resource Description</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-pdf-representation-of-a-resource">/repositories/:repo_id/resource_descriptions/:id.pdf</a></td>
        <td>GET</td>
        <td>Get a PDF representation of a Resource</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-ead-representation-of-a-resource">/repositories/:repo_id/resource_descriptions/:id.xml</a></td>
        <td>GET</td>
        <td>Get an EAD representation of a Resource</td>
      </tr>
    
      <tr>
        <td><a href="#get-export-metadata-for-resource-labels">/repositories/:repo_id/resource_labels/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get export metadata for Resource labels</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-tsv-list-of-printable-labels-for-a-resource">/repositories/:repo_id/resource_labels/:id.tsv</a></td>
        <td>GET</td>
        <td>Get a tsv list of printable labels for a Resource</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-resource">/repositories/:repo_id/resources</a></td>
        <td>POST</td>
        <td>Create a Resource</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-resources-for-a-repository">/repositories/:repo_id/resources</a></td>
        <td>GET</td>
        <td>Get a list of Resources for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-resource">/repositories/:repo_id/resources/:id</a></td>
        <td>GET</td>
        <td>Get a Resource</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-resource">/repositories/:repo_id/resources/:id</a></td>
        <td>POST</td>
        <td>Update a Resource</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-resource">/repositories/:repo_id/resources/:id</a></td>
        <td>DELETE</td>
        <td>Delete a Resource</td>
      </tr>
    
      <tr>
        <td><a href="#move-existing-archival-objects-to-become-children-of-a-resource">/repositories/:repo_id/resources/:id/accept_children</a></td>
        <td>POST</td>
        <td>Move existing Archival Objects to become children of a Resource</td>
      </tr>
    
      <tr>
        <td><a href="#batch-create-several-archival-objects-as-children-of-an-existing-resource">/repositories/:repo_id/resources/:id/children</a></td>
        <td>POST</td>
        <td>Batch create several Archival Objects as children of an existing Resource</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-record-types-in-the-graph-of-a-resource">/repositories/:repo_id/resources/:id/models_in_graph</a></td>
        <td>GET</td>
        <td>Get a list of record types in the graph of a resource</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-list-of-uris-of-this-published-resource-and-all-published-archival-objects-contained-within-ordered-by-tree-order--i-e--if-you-fully-expanded-the-record-tree-and-read-from-top-to-bottom">/repositories/:repo_id/resources/:id/ordered_records</a></td>
        <td>GET</td>
        <td>Get the list of URIs of this published resource and all published archival objects contained within.Ordered by tree order (i.e. if you fully expanded the record tree and read from top to bottom)</td>
      </tr>
    
      <tr>
        <td><a href="#publish-a-resource-and-all-its-sub-records-and-components">/repositories/:repo_id/resources/:id/publish</a></td>
        <td>POST</td>
        <td>Publish a resource and all its sub-records and components</td>
      </tr>
    
      <tr>
        <td><a href="#suppress-this-record">/repositories/:repo_id/resources/:id/suppressed</a></td>
        <td>POST</td>
        <td>Suppress this record</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-csv-template-useful-for-bulk-creating-containers-for-archival-objects-of-a-resource">/repositories/:repo_id/resources/:id/templates/top_container_creation.csv</a></td>
        <td>GET</td>
        <td>Get a CSV template useful for bulk-creating containers for archival objects of a resource</td>
      </tr>
    
      <tr>
        <td><a href="#get-top-containers-linked-to-a-published-resource-and-published-archival-ojbects-contained-within">/repositories/:repo_id/resources/:id/top_containers</a></td>
        <td>GET</td>
        <td>Get Top Containers linked to a published resource and published archival ojbects contained within.</td>
      </tr>
    
      <tr>
        <td><a href="#transfer-this-record-to-a-different-repository">/repositories/:repo_id/resources/:id/transfer</a></td>
        <td>POST</td>
        <td>Transfer this record to a different repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-resource-tree">/repositories/:repo_id/resources/:id/tree</a></td>
        <td>GET</td>
        <td>Get a Resource tree</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-tree-information-for-an-archival-object-record-within-a-tree">/repositories/:repo_id/resources/:id/tree/node</a></td>
        <td>GET</td>
        <td>Fetch tree information for an Archival Object record within a tree</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-tree-paths-from-the-root-record-to-archival-objects">/repositories/:repo_id/resources/:id/tree/node_from_root</a></td>
        <td>GET</td>
        <td>Fetch tree paths from the root record to Archival Objects</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-tree-information-for-the-top-level-resource-record">/repositories/:repo_id/resources/:id/tree/root</a></td>
        <td>GET</td>
        <td>Fetch tree information for the top-level resource record</td>
      </tr>
    
      <tr>
        <td><a href="#fetch-the-record-slice-for-a-given-tree-waypoint">/repositories/:repo_id/resources/:id/tree/waypoint</a></td>
        <td>GET</td>
        <td>Fetch the record slice for a given tree waypoint</td>
      </tr>
    
      <tr>
        <td><a href="#unpublish-a-resource-and-all-its-sub-records-and-components">/repositories/:repo_id/resources/:id/unpublish</a></td>
        <td>POST</td>
        <td>Unpublish a resource and all its sub-records and components</td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-a-marc21-export">/repositories/:repo_id/resources/marc21/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for a MARC21 export</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-marc-21-representation-of-a-resource">/repositories/:repo_id/resources/marc21/:id.xml</a></td>
        <td>GET</td>
        <td>Get a MARC 21 representation of a Resource</td>
      </tr>
    
      <tr>
        <td><a href="#search-this-repository">/repositories/:repo_id/search</a></td>
        <td>GET, POST</td>
        <td>Search this repository</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-top-container">/repositories/:repo_id/top_containers</a></td>
        <td>POST</td>
        <td>Create a top container</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-topcontainers-for-a-repository">/repositories/:repo_id/top_containers</a></td>
        <td>GET</td>
        <td>Get a list of TopContainers for a Repository</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-top-container">/repositories/:repo_id/top_containers/:id</a></td>
        <td>POST</td>
        <td>Update a top container</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-top-container-by-id">/repositories/:repo_id/top_containers/:id</a></td>
        <td>GET</td>
        <td>Get a top container by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-top-container">/repositories/:repo_id/top_containers/:id</a></td>
        <td>DELETE</td>
        <td>Delete a top container</td>
      </tr>
    
      <tr>
        <td><a href="#update-container-profile-for-a-batch-of-top-containers">/repositories/:repo_id/top_containers/batch/container_profile</a></td>
        <td>POST</td>
        <td>Update container profile for a batch of top containers</td>
      </tr>
    
      <tr>
        <td><a href="#update-ils-holding-id-for-a-batch-of-top-containers">/repositories/:repo_id/top_containers/batch/ils_holding_id</a></td>
        <td>POST</td>
        <td>Update ils_holding_id for a batch of top containers</td>
      </tr>
    
      <tr>
        <td><a href="#update-location-for-a-batch-of-top-containers">/repositories/:repo_id/top_containers/batch/location</a></td>
        <td>POST</td>
        <td>Update location for a batch of top containers</td>
      </tr>
    
      <tr>
        <td><a href="#bulk-update-barcodes">/repositories/:repo_id/top_containers/bulk/barcodes</a></td>
        <td>POST</td>
        <td>Bulk update barcodes</td>
      </tr>
    
      <tr>
        <td><a href="#bulk-update-locations">/repositories/:repo_id/top_containers/bulk/locations</a></td>
        <td>POST</td>
        <td>Bulk update locations</td>
      </tr>
    
      <tr>
        <td><a href="#search-for-top-containers">/repositories/:repo_id/top_containers/search</a></td>
        <td>GET</td>
        <td>Search for top containers</td>
      </tr>
    
      <tr>
        <td><a href="#transfer-this-record-to-a-different-repository">/repositories/:repo_id/transfer</a></td>
        <td>POST</td>
        <td>Transfer this record to a different repository</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-user-s-details-including-their-groups-for-the-current-repository">/repositories/:repo_id/users/:id</a></td>
        <td>GET</td>
        <td>Get a user's details including their groups for the current repository</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-repository-with-an-agent-representation">/repositories/with_agent</a></td>
        <td>POST</td>
        <td>Create a Repository with an agent representation</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-repository-by-id--including-its-agent-representation">/repositories/with_agent/:id</a></td>
        <td>GET</td>
        <td>Get a Repository by ID, including its agent representation</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-repository-with-an-agent-representation">/repositories/with_agent/:id</a></td>
        <td>POST</td>
        <td>Update a repository with an agent representation</td>
      </tr>
    
      <tr>
        <td><a href="#get-all-archivesspace-schemas">/schemas</a></td>
        <td>GET</td>
        <td>Get all ArchivesSpace schemas</td>
      </tr>
    
      <tr>
        <td><a href="#get-an-archivesspace-schema">/schemas/:schema</a></td>
        <td>GET</td>
        <td>Get an ArchivesSpace schema</td>
      </tr>
    
      <tr>
        <td><a href="#search-this-archive">/search</a></td>
        <td>GET, POST</td>
        <td>Search this archive</td>
      </tr>
    
      <tr>
        <td><a href="#search-across-location-profiles">/search/location_profile</a></td>
        <td>GET</td>
        <td>Search across Location Profiles</td>
      </tr>
    
      <tr>
        <td><a href="#find-the-tree-view-for-a-particular-archival-record">/search/published_tree</a></td>
        <td>GET</td>
        <td>Find the tree view for a particular archival record</td>
      </tr>
    
      <tr>
        <td><a href="#return-the-counts-of-record-types-of-interest-by-repository">/search/record_types_by_repository</a></td>
        <td>GET, POST</td>
        <td>Return the counts of record types of interest by repository</td>
      </tr>
    
      <tr>
        <td><a href="#return-a-set-of-records-by-uri">/search/records</a></td>
        <td>GET, POST</td>
        <td>Return a set of records by URI</td>
      </tr>
    
      <tr>
        <td><a href="#search-across-repositories">/search/repositories</a></td>
        <td>GET, POST</td>
        <td>Search across repositories</td>
      </tr>
    
      <tr>
        <td><a href="#search-across-subjects">/search/subjects</a></td>
        <td>GET, POST</td>
        <td>Search across subjects</td>
      </tr>
    
      <tr>
        <td><a href="#find-the-record-given-the-slug--return-id--repo-id--and-table-name">/slug</a></td>
        <td>GET</td>
        <td>Find the record given the slug, return id, repo_id, and table name</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-location-by-id">/space_calculator/buildings</a></td>
        <td>GET</td>
        <td>Get a Location by ID</td>
      </tr>
    
      <tr>
        <td><a href="#calculate-how-many-containers-will-fit-in-locations-for-a-given-building">/space_calculator/by_building</a></td>
        <td>GET</td>
        <td>Calculate how many containers will fit in locations for a given building</td>
      </tr>
    
      <tr>
        <td><a href="#calculate-how-many-containers-will-fit-in-a-list-of-locations">/space_calculator/by_location</a></td>
        <td>GET</td>
        <td>Calculate how many containers will fit in a list of locations</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-subject">/subjects</a></td>
        <td>POST</td>
        <td>Create a Subject</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-subjects">/subjects</a></td>
        <td>GET</td>
        <td>Get a list of Subjects</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-subject">/subjects/:id</a></td>
        <td>POST</td>
        <td>Update a Subject</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-subject-by-id">/subjects/:id</a></td>
        <td>GET</td>
        <td>Get a Subject by ID</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-subject">/subjects/:id</a></td>
        <td>DELETE</td>
        <td>Delete a Subject</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-terms-matching-a-prefix">/terms</a></td>
        <td>GET</td>
        <td>Get a list of Terms matching a prefix</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-stream-of-updated-records">/update-feed</a></td>
        <td>GET</td>
        <td>Get a stream of updated records</td>
      </tr>
    
      <tr>
        <td><a href="#refresh-the-list-of-currently-known-edits">/update_monitor</a></td>
        <td>POST</td>
        <td>Refresh the list of currently known edits</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-local-user">/users</a></td>
        <td>POST</td>
        <td>Create a local user</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-users">/users</a></td>
        <td>GET</td>
        <td>Get a list of users</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-user-s-details--including-their-current-permissions">/users/:id</a></td>
        <td>GET</td>
        <td>Get a user's details (including their current permissions)</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-user-s-account">/users/:id</a></td>
        <td>POST</td>
        <td>Update a user's account</td>
      </tr>
    
      <tr>
        <td><a href="#delete-a-user">/users/:id</a></td>
        <td>DELETE</td>
        <td>Delete a user</td>
      </tr>
    
      <tr>
        <td><a href="#set-a-user-to-be-activated">/users/:id/activate</a></td>
        <td>GET</td>
        <td>Set a user to be activated</td>
      </tr>
    
      <tr>
        <td><a href="#set-a-user-to-be-deactivated">/users/:id/deactivate</a></td>
        <td>GET</td>
        <td>Set a user to be deactivated</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-user-s-groups">/users/:id/groups</a></td>
        <td>POST</td>
        <td>Update a user's groups</td>
      </tr>
    
      <tr>
        <td><a href="#become-a-different-user">/users/:username/become-user</a></td>
        <td>POST</td>
        <td>Become a different user</td>
      </tr>
    
      <tr>
        <td><a href="#log-in">/users/:username/login</a></td>
        <td>POST</td>
        <td>Log in</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-system-users">/users/complete</a></td>
        <td>GET</td>
        <td>Get a list of system users</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-currently-logged-in-user">/users/current-user</a></td>
        <td>GET</td>
        <td>Get the currently logged in user</td>
      </tr>
    
      <tr>
        <td><a href="#get-the-archivesspace-application-version">/version</a></td>
        <td>GET</td>
        <td>Get the ArchivesSpace application version</td>
      </tr>
    
      <tr>
        <td><a href="#create-a-vocabulary">/vocabularies</a></td>
        <td>POST</td>
        <td>Create a Vocabulary</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-vocabularies">/vocabularies</a></td>
        <td>GET</td>
        <td>Get a list of Vocabularies</td>
      </tr>
    
      <tr>
        <td><a href="#update-a-vocabulary">/vocabularies/:id</a></td>
        <td>POST</td>
        <td>Update a Vocabulary</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-vocabulary-by-id">/vocabularies/:id</a></td>
        <td>GET</td>
        <td>Get a Vocabulary by ID</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-list-of-terms-for-a-vocabulary">/vocabularies/:id/terms</a></td>
        <td>GET</td>
        <td>Get a list of Terms for a Vocabulary</td>
      </tr>
    
  </tbody>
</table>
