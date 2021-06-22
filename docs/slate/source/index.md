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

# Common Parameters

As you use the ArchivesSpace API, you may start to notice similarities between different endpoints, and arguments that repeatedly show up in URLs or parameter lists.  Some of the most general bear special description.

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
As of 2020-11-11 13:20:40 -0500 the following REST endpoints exist in the master branch of the development repository:


## Create a corporate entity agent



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number_type":"home",
"number":"116 04140 272 36318"}],
"name":"Name Number 5",
"address_1":"228305FLV",
"country":"Y998GQS",
"fax":"756R109R789",
"note":"TS543YO"}],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"2004-01-06",
"end":"2004-01-06",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"181409480C719"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"primary_name":"Name Number 4",
"subordinate_name_1":"LWL410G",
"subordinate_name_2":"584610OCT",
"number":"I547907L821",
"sort_name":"SORT s - 2",
"dates":"640781J70P",
"qualifier":"37631O993614",
"authority_id":"http://www.example-2.com",
"source":"local"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089/agents/corporate_entities"

```


__Endpoint__

```[:POST] /agents/corporate_entities ```

__Description__

Create a corporate entity agent


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:agent_corporate_entity) <request body> -- The record to create
  

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

List all corporate entity agents


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
"number_type":"home",
"number":"116 04140 272 36318"}],
"name":"Name Number 5",
"address_1":"228305FLV",
"country":"Y998GQS",
"fax":"756R109R789",
"note":"TS543YO"}],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"2004-01-06",
"end":"2004-01-06",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"181409480C719"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"rda",
"primary_name":"Name Number 4",
"subordinate_name_1":"LWL410G",
"subordinate_name_2":"584610OCT",
"number":"I547907L821",
"sort_name":"SORT s - 2",
"dates":"640781J70P",
"qualifier":"37631O993614",
"authority_id":"http://www.example-2.com",
"source":"local"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}' \
  "http://localhost:8089/agents/corporate_entities/1"

```


__Endpoint__

```[:POST] /agents/corporate_entities/:id ```

__Description__

Update a corporate entity agent


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:agent_corporate_entity) <request body> -- The updated record
  

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

Get a corporate entity by ID


__Parameters__

  
    
  
  
  
	  Integer id -- ID of the corporate entity agent
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete a corporate entity agent


__Parameters__

  
    
  
  
  
	  Integer id -- ID of the corporate entity agent
  

__Returns__

  	200 -- deleted




## Create a family agent



  
    
  

  
    
  
  
  
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
"date_type":"inclusive",
"label":"existence",
"begin":"1992-04-30",
"end":"1992-04-30",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"780BC244Q"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"family_name":"Name Number 6",
"sort_name":"SORT h - 3",
"dates":"TF750501T",
"qualifier":"VHC132O",
"prefix":"728222617OI",
"authority_id":"http://www.example-3.com",
"source":"naf"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089/agents/families"

```


__Endpoint__

```[:POST] /agents/families ```

__Description__

Create a family agent


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:agent_family) <request body> -- The record to create
  

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

List all family agents


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
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"inclusive",
"label":"existence",
"begin":"1992-04-30",
"end":"1992-04-30",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"780BC244Q"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_family",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"family_name":"Name Number 6",
"sort_name":"SORT h - 3",
"dates":"TF750501T",
"qualifier":"VHC132O",
"prefix":"728222617OI",
"authority_id":"http://www.example-3.com",
"source":"naf"}],
"related_agents":[],
"agent_type":"agent_family"}' \
  "http://localhost:8089/agents/families/1"

```


__Endpoint__

```[:POST] /agents/families/:id ```

__Description__

Update a family agent


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:agent_family) <request body> -- The updated record
  

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

Get a family by ID


__Parameters__

  
    
  
  
  
	  Integer id -- ID of the family agent
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete an agent family


__Parameters__

  
    
  
  
  
	  Integer id -- ID of the family agent
  

__Returns__

  	200 -- deleted




## Create a person agent



  
    
  

  
    
  
  
  
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
"date_type":"range",
"label":"existence",
"begin":"2020-01-28",
"end":"2020-01-28",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"E288Y51084"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"source":"local",
"primary_name":"Name Number 7",
"sort_name":"SORT n - 4",
"name_order":"direct",
"number":"I10J668111",
"dates":"674MWUJ",
"qualifier":"TOKQ871",
"fuller_form":"YA852XD",
"suffix":"SXDBQ",
"rest_of_name":"Y916E293A",
"authority_id":"http://www.example-4.com"}],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089/agents/people"

```


__Endpoint__

```[:POST] /agents/people ```

__Description__

Create a person agent


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:agent_person) <request body> -- The record to create
  

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

List all person agents


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
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"2020-01-28",
"end":"2020-01-28",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"E288Y51084"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_person",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"source":"local",
"primary_name":"Name Number 7",
"sort_name":"SORT n - 4",
"name_order":"direct",
"number":"I10J668111",
"dates":"674MWUJ",
"qualifier":"TOKQ871",
"fuller_form":"YA852XD",
"suffix":"SXDBQ",
"rest_of_name":"Y916E293A",
"authority_id":"http://www.example-4.com"}],
"related_agents":[],
"agent_type":"agent_person"}' \
  "http://localhost:8089/agents/people/1"

```


__Endpoint__

```[:POST] /agents/people/:id ```

__Description__

Update a person agent


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:agent_person) <request body> -- The updated record
  

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

Get a person by ID


__Parameters__

  
    
  
  
  
	  Integer id -- ID of the person agent
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete an agent person


__Parameters__

  
    
  
  
  
	  Integer id -- ID of the person agent
  

__Returns__

  	200 -- deleted




## Create a software agent



  
    
  

  
    
  
  
  
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
"date_type":"single",
"label":"existence",
"begin":"2017-08-13",
"end":"2017-08-13",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"JUP799R"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"source":"local",
"software_name":"Name Number 8",
"sort_name":"SORT a - 5",
"dates":"C45NV615",
"qualifier":"Y896170836X",
"authority_id":"http://www.example-5.com"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089/agents/software"

```


__Endpoint__

```[:POST] /agents/software ```

__Description__

Create a software agent


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:agent_software) <request body> -- The record to create
  

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

List all software agents


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
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"single",
"label":"existence",
"begin":"2017-08-13",
"end":"2017-08-13",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"JUP799R"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_software",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"dacs",
"source":"local",
"software_name":"Name Number 8",
"sort_name":"SORT a - 5",
"dates":"C45NV615",
"qualifier":"Y896170836X",
"authority_id":"http://www.example-5.com"}],
"agent_type":"agent_software"}' \
  "http://localhost:8089/agents/software/1"

```


__Endpoint__

```[:POST] /agents/software/:id ```

__Description__

Update a software agent


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:agent_software) <request body> -- The updated record
  

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

Get a software agent by ID


__Parameters__

  
    
  
  
  
	  Integer id -- ID of the software agent
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete a software agent


__Parameters__

  
    
  
  
  
	  Integer id -- ID of the software agent
  

__Returns__

  	200 -- deleted




## Redirect to resource identified by ARK Name



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/ark*/1/1"

```


__Endpoint__

```[:GET] /ark*/:naan/:id ```

__Description__

Redirect to resource identified by ARK Name


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  

__Returns__

  	404 -- Not found

  	302 -- redirect




## Carry out delete requests against a list of records



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/batch_delete?record_uris=M829439S549"

```


__Endpoint__

```[:POST] /batch_delete ```

__Description__

Carry out delete requests against a list of records


__Parameters__

  
    
  
  
  
	  [String] record_uris -- A list of record uris
  

__Returns__

  	200 -- deleted




## List records by their external ID(s)



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/by-external-id?eid=U550JGS&type=XVT913C"

```


__Endpoint__

```[:GET] /by-external-id ```

__Description__

List records by their external ID(s)


__Parameters__

  
    
  
  
  
	  String eid -- An external ID to find
  
  
    
  
  
    
    
  
  
	  [String] type (Optional) -- The record type to search (useful if IDs may be shared between different types)
  

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

Get an Enumeration Value


__Parameters__

  
    
  
  
  
	  Integer enum_val_id -- The ID of the enumeration value to retrieve
  

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

Update an enumeration value


__Parameters__

  
    
  
  
  
	  Integer enum_val_id -- The ID of the enumeration value to update
  
  
    
  
  
    
    
  
  
	  JSONModel(:enumeration_value) <request body> -- The enumeration value to update
  

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

Update the position of an ennumeration value


__Parameters__

  
    
  
  
  
	  Integer enum_val_id -- The ID of the enumeration value to update
  
  
    
  
  
  
	  Integer position -- The target position in the value list
  

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

Suppress this value


__Parameters__

  
    
  
  
  
	  Integer enum_val_id -- The ID of the enumeration value to update
  
  
    
  
  
  
	  RESTHelpers::BooleanParam suppressed -- Suppression state
  

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

List all defined enumerations


__Parameters__


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

Create an enumeration


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:enumeration) <request body> -- The record to create
  

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

Update an enumeration


__Parameters__

  
    
  
  
  
	  Integer enum_id -- The ID of the enumeration to update
  
  
    
  
  
    
    
  
  
	  JSONModel(:enumeration) <request body> -- The enumeration to update
  

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

Get an Enumeration


__Parameters__

  
    
  
  
  
	  Integer enum_id -- The ID of the enumeration to retrieve
  

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

List all defined enumerations as a csv


__Parameters__


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

Migrate all records from one value to another


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:enumeration_migration) <request body> -- The migration request
  

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

Get an Enumeration by Name


__Parameters__

  
    
  
  
  
	  String enum_name -- The name of the enumeration to retrieve
  

__Returns__

  	200 -- (:enumeration)




## Create a Container_Profile



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"container_profile",
"name":"L959GY311",
"url":"DKQ829S",
"dimension_units":"inches",
"extent_dimension":"width",
"depth":"42",
"height":"56",
"width":"93"}' \
  "http://localhost:8089/container_profiles"

```


__Endpoint__

```[:POST] /container_profiles ```

__Description__

Create a Container_Profile


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:container_profile) <request body> -- The record to create
  

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

Get a list of Container Profiles


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
"name":"L959GY311",
"url":"DKQ829S",
"dimension_units":"inches",
"extent_dimension":"width",
"depth":"42",
"height":"56",
"width":"93"}' \
  "http://localhost:8089/container_profiles/1"

```


__Endpoint__

```[:POST] /container_profiles/:id ```

__Description__

Update a Container Profile


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:container_profile) <request body> -- The updated record
  

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

Get a Container Profile by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete an Container Profile


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  

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

Get the global Preferences records for the current user.


__Parameters__


__Returns__

  	200 -- {(:preference)}




## Calculate the dates of an archival object tree



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/date_calculator?record_uri=TWRP79&label=KYWO183"

```


__Endpoint__

```[:GET] /date_calculator ```

__Description__

Calculate the dates of an archival object tree


__Parameters__

  
    
  
  
  
	  String record_uri -- The uri of the object
  
  
    
  
  
    
    
  
  
	  String label (Optional) -- The date label to filter on
  

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

Get a stream of deleted records


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
  "http://localhost:8089/extent_calculator?record_uri=AH412U331&unit=68J696513P"

```


__Endpoint__

```[:GET] /extent_calculator ```

__Description__

Calculate the extent of an archival object tree


__Parameters__

  
    
  
  
  
	  String record_uri -- The uri of the object
  
  
    
  
  
    
    
  
  
	  String unit (Optional) -- The unit of measurement to use
  

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

List all supported job types


__Parameters__


__Returns__

  	200 -- A list of supported job types




## Create a Location_Profile



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location_profile",
"name":"HDWKT",
"dimension_units":"inches",
"depth":"30",
"height":"14",
"width":"86"}' \
  "http://localhost:8089/location_profiles"

```


__Endpoint__

```[:POST] /location_profiles ```

__Description__

Create a Location_Profile


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:location_profile) <request body> -- The record to create
  

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

Get a list of Location Profiles


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
"name":"HDWKT",
"dimension_units":"inches",
"depth":"30",
"height":"14",
"width":"86"}' \
  "http://localhost:8089/location_profiles/1"

```


__Endpoint__

```[:POST] /location_profiles/:id ```

__Description__

Update a Location Profile


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:location_profile) <request body> -- The updated record
  

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

Get a Location Profile by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete an Location Profile


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  

__Returns__

  	200 -- deleted




## Create a Location



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"location",
"external_ids":[],
"functions":[],
"building":"8 W 9th Street",
"floor":"10",
"room":"9",
"area":"Back",
"barcode":"00110010011011010011",
"temporary":"reading_room"}' \
  "http://localhost:8089/locations"

```


__Endpoint__

```[:POST] /locations ```

__Description__

Create a Location


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:location) <request body> -- The record to create
  

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

Get a list of locations


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
"building":"8 W 9th Street",
"floor":"10",
"room":"9",
"area":"Back",
"barcode":"00110010011011010011",
"temporary":"reading_room"}' \
  "http://localhost:8089/locations/1"

```


__Endpoint__

```[:POST] /locations/:id ```

__Description__

Update a Location


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:location) <request body> -- The updated record
  

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

Get a Location by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete a Location


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  

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

Create a Batch of Locations


__Parameters__

  
    
  
  
    
    
  
  
	  RESTHelpers::BooleanParam dry_run (Optional) -- If true, don't create the locations, just list them
  
  
    
  
  
    
    
  
  
	  JSONModel(:location_batch) <request body> -- The location batch data to generate all locations
  

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

Update a Location


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:location_batch_update) <request body> -- The location batch data to update all locations
  

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

Log out the current session


__Parameters__


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

Carry out a merge request against Agent records


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:merge_request) <request body> -- A merge request
  

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}




## Carry out a detailed merge request against Agent records



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/merge_requests/agent_detail?dry_run=true"

```


__Endpoint__

```[:POST] /merge_requests/agent_detail ```

__Description__

Carry out a detailed merge request against Agent records


__Parameters__

  
    
  
  
    
    
  
  
	  RESTHelpers::BooleanParam dry_run (Optional) -- If true, don't process the merge, just display the merged record
  
  
    
  
  
    
    
  
  
	  JSONModel(:merge_request_detail) <request body> -- A detailed merge request
  

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

Carry out a merge request against Container Profile records


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:merge_request) <request body> -- A merge request
  

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

Carry out a merge request against Digital_Object records


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  JSONModel(:merge_request) <request body> -- A merge request
  

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

Carry out a merge request against Resource records


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  JSONModel(:merge_request) <request body> -- A merge request
  

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

Carry out a merge request against Subject records


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:merge_request) <request body> -- A merge request
  

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

Carry out a merge request against Top Container records


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  JSONModel(:merge_request) <request body> -- A merge request
  

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

Get a stream of notifications


__Parameters__

  
    
  
  
    
    
  
  
	  Integer last_sequence (Optional) -- The last sequence number seen
  

__Returns__

  	200 -- a list of notifications




## Get a list of Permissions



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/permissions?level=782192485R403"

```


__Endpoint__

```[:GET] /permissions ```

__Description__

Get a list of Permissions


__Parameters__

  
    
  
  
    
    
  
  
	  String level -- The permission level to get (one of: repository, global, all) -- Must be one of repository, global, all
  

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

List all reports


__Parameters__


__Returns__

  	200 -- report list in json




## Get a static asset for a report



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/reports/static/*?splat=251KI93H"

```


__Endpoint__

```[:GET] /reports/static/* ```

__Description__

Get a static asset for a report


__Parameters__

  
    
  
  
  
	  String splat -- The requested asset
  

__Returns__

  	200 -- the asset




## Create a Repository



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"repository",
"name":"Description: 11",
"is_slug_auto":true,
"repo_code":"ASPACE REPO 2 -- 264583",
"org_code":"ABQMQ",
"image_url":"http://www.example-12.com",
"url":"http://www.example-13.com",
"country":"US"}' \
  "http://localhost:8089/repositories"

```


__Endpoint__

```[:POST] /repositories ```

__Description__

Create a Repository


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:repository) <request body> -- The record to create
  

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

Get a list of Repositories


__Parameters__

  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

__Returns__

  	200 -- [(:repository)]




## Update a repository



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"repository",
"name":"Description: 11",
"is_slug_auto":true,
"repo_code":"ASPACE REPO 2 -- 264583",
"org_code":"ABQMQ",
"image_url":"http://www.example-12.com",
"url":"http://www.example-13.com",
"country":"US"}' \
  "http://localhost:8089/repositories/1"

```


__Endpoint__

```[:POST] /repositories/:id ```

__Description__

Update a repository


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:repository) <request body> -- The updated record
  

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

Get a Repository by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete a Repository


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Create an Accession



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"accession",
"external_ids":[],
"is_slug_auto":true,
"related_accessions":[],
"accession_date":"2006-03-22",
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
"id_0":"644UBQU",
"id_1":"Y510SAY",
"id_2":"LYOAV",
"id_3":"405HW31C",
"title":"Accession Title: 1",
"content_description":"Description: 2",
"condition_description":"Description: 3"}' \
  "http://localhost:8089/repositories/2/accessions"

```


__Endpoint__

```[:POST] /repositories/:repo_id/accessions ```

__Description__

Create an Accession


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:accession) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Accessions for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- [(:accession)]




## Update an Accession



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"accession",
"external_ids":[],
"is_slug_auto":true,
"related_accessions":[],
"accession_date":"2006-03-22",
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
"id_0":"644UBQU",
"id_1":"Y510SAY",
"id_2":"LYOAV",
"id_3":"405HW31C",
"title":"Accession Title: 1",
"content_description":"Description: 2",
"condition_description":"Description: 3"}' \
  "http://localhost:8089/repositories/2/accessions/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/accessions/:id ```

__Description__

Update an Accession


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:accession) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get an Accession by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete an Accession


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Suppress this record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  RESTHelpers::BooleanParam suppressed -- Suppression state
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get Top Containers linked to an Accession


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

__Returns__

  	200 -- a list of linked top containers

  	404 -- Not found




## Transfer this record to a different repository



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/accessions/1/transfer?target_repo=909ECDK"

```


__Endpoint__

```[:POST] /repositories/:repo_id/accessions/:id/transfer ```

__Description__

Transfer this record to a different repository


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  String target_repo -- The URI of the target repository
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- moved




## Get metadata for an EAC-CPF export of a corporate entity



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_contexts/corporate_entities/1.:fmt/metadata"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata ```

__Description__

Get metadata for an EAC-CPF export of a corporate entity


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- The export metadata




## Get an EAC-CPF representation of a Corporate Entity



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_contexts/corporate_entities/1.xml"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/corporate_entities/:id.xml ```

__Description__

Get an EAC-CPF representation of a Corporate Entity


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- (:agent)




## Get metadata for an EAC-CPF export of a family



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_contexts/families/1.:fmt/metadata"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata ```

__Description__

Get metadata for an EAC-CPF export of a family


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- The export metadata




## Get an EAC-CPF representation of a Family



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_contexts/families/1.xml"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/families/:id.xml ```

__Description__

Get an EAC-CPF representation of a Family


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- (:agent)




## Get metadata for an EAC-CPF export of a person



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_contexts/people/1.:fmt/metadata"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata ```

__Description__

Get metadata for an EAC-CPF export of a person


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- The export metadata




## Get an EAC-CPF representation of an Agent



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_contexts/people/1.xml"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/people/:id.xml ```

__Description__

Get an EAC-CPF representation of an Agent


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- (:agent)




## Get metadata for an EAC-CPF export of a software



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_contexts/softwares/1.:fmt/metadata"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/softwares/:id.:fmt/metadata ```

__Description__

Get metadata for an EAC-CPF export of a software


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- The export metadata




## Get an EAC-CPF representation of a Software agent



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_contexts/softwares/1.xml"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_contexts/softwares/:id.xml ```

__Description__

Get an EAC-CPF representation of a Software agent


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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
"ref_id":"836QX399J",
"level":"subseries",
"title":"Archival Object Title: 2",
"resource":{ "ref":"/repositories/2/resources/1"}}' \
  "http://localhost:8089/repositories/2/archival_objects"

```


__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects ```

__Description__

Create an Archival Object


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:archival_object) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Archival Objects for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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
"ref_id":"836QX399J",
"level":"subseries",
"title":"Archival Object Title: 2",
"resource":{ "ref":"/repositories/2/resources/1"}}' \
  "http://localhost:8089/repositories/2/archival_objects/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id ```

__Description__

Update an Archival Object


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:archival_object) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get an Archival Object by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete an Archival Object


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Move existing Archival Objects to become children of an Archival Object



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/accept_children?children=742X930559Q&position=1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/accept_children ```

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




## Get the children of an Archival Object



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_objects/1/children"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_objects/:id/children ```

__Description__

Get the children of an Archival Object


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- a list of archival object references

  	404 -- Not found




## Batch create several Archival Objects as children of an existing Archival Object



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/archival_objects/1/children"

```


__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/children ```

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




## Set the parent/position of an Archival Object in a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/parent?parent=1&position=1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/parent ```

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




## Get the previous record in the tree for an Archival Object



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/archival_objects/1/previous"

```


__Endpoint__

```[:GET] /repositories/:repo_id/archival_objects/:id/previous ```

__Description__

Get the previous record in the tree for an Archival Object


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- (:archival_object)

  	404 -- No previous node




## Suppress this record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/archival_objects/1/suppressed?suppressed=true"

```


__Endpoint__

```[:POST] /repositories/:repo_id/archival_objects/:id/suppressed ```

__Description__

Suppress this record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  RESTHelpers::BooleanParam suppressed -- Suppression state
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## Update this repository's assessment attribute definitions



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/assessment_attribute_definitions"

```


__Endpoint__

```[:POST] /repositories/:repo_id/assessment_attribute_definitions ```

__Description__

Update this repository's assessment attribute definitions


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  JSONModel(:assessment_attribute_definitions) <request body> -- The assessment attribute definitions
  

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

Get this repository's assessment attribute definitions


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Create an Assessment


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:assessment) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Assessments for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Update an Assessment


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:assessment) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get an Assessment by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete an Assessment


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Import a batch of records



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"body_stream"' \
  "http://localhost:8089/repositories/2/batch_imports?migration=330J158391B&skip_results=true"

```


__Endpoint__

```[:POST] /repositories/:repo_id/batch_imports ```

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




## Create a Classification Term



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"classification_term",
"publish":true,
"path_from_root":[],
"linked_records":[],
"is_slug_auto":true,
"identifier":"S160788J621",
"title":"Classification Title: 4",
"description":"Description: 5",
"classification":{ "ref":"/repositories/2/classifications/1"}}' \
  "http://localhost:8089/repositories/2/classification_terms"

```


__Endpoint__

```[:POST] /repositories/:repo_id/classification_terms ```

__Description__

Create a Classification Term


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:classification_term) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Classification Terms for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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
"identifier":"S160788J621",
"title":"Classification Title: 4",
"description":"Description: 5",
"classification":{ "ref":"/repositories/2/classifications/1"}}' \
  "http://localhost:8089/repositories/2/classification_terms/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/classification_terms/:id ```

__Description__

Update a Classification Term


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:classification_term) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a Classification Term by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete a Classification Term


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Move existing Classification Terms to become children of another Classification Term



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/classification_terms/1/accept_children?children=C65P478L&position=1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/classification_terms/:id/accept_children ```

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




## Get the children of a Classification Term



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classification_terms/1/children"

```


__Endpoint__

```[:GET] /repositories/:repo_id/classification_terms/:id/children ```

__Description__

Get the children of a Classification Term


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Set the parent/position of a Classification Term in a tree


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer parent (Optional) -- The parent of this node in the tree
  
  
    
  
  
    
    
  
  
	  Integer position (Optional) -- The position of this node in the tree
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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
"identifier":"S469WMO",
"title":"Classification Title: 3",
"description":"Description: 4"}' \
  "http://localhost:8089/repositories/2/classifications"

```


__Endpoint__

```[:POST] /repositories/:repo_id/classifications ```

__Description__

Create a Classification


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:classification) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Classifications for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a Classification


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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
"identifier":"S469WMO",
"title":"Classification Title: 3",
"description":"Description: 4"}' \
  "http://localhost:8089/repositories/2/classifications/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/classifications/:id ```

__Description__

Update a Classification


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:classification) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Delete a Classification


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Move existing Classification Terms to become children of a Classification



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/classifications/1/accept_children?children=383K120VY&position=1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/classifications/:id/accept_children ```

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




## Get a Classification tree



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree"

```


__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree ```

__Description__

Get a Classification tree


__Parameters__
<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Call the */tree/{root,waypoint,node} endpoints to traverse record trees.  See backend/app/model/large_tree.rb for further information.</p>
  
</aside>


  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- OK




## Fetch tree information for an Classification Term record within a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree/node?node_uri=85858N982612&published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree/node ```

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




## Fetch tree path from the root record to Classification Terms



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree/node_from_root?node_ids=1&published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree/node_from_root ```

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




## Fetch tree information for the top-level classification record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree/root?published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree/root ```

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




## Fetch the record slice for a given tree waypoint



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/classifications/1/tree/waypoint?offset=1&parent_node=AJ836TP&published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/classifications/:id/tree/waypoint ```

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




## Get a Collection Management Record by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/collection_management/1?resolve[]=[record_types, to_resolve]"

```


__Endpoint__

```[:GET] /repositories/:repo_id/collection_management/:id ```

__Description__

Get a Collection Management Record by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

__Returns__

  	200 -- (:collection_management)




## Transfer components from one resource to another



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/component_transfers?target_resource=Y608PMX&component=QALW866"

```


__Endpoint__

```[:POST] /repositories/:repo_id/component_transfers ```

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




## Get the Preferences records for the current repository and user.



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/current_preferences"

```


__Endpoint__

```[:GET] /repositories/:repo_id/current_preferences ```

__Description__

Get the Preferences records for the current repository and user.


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {(:preference)}




## Save defaults for a record type



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/default_values/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/default_values/:record_type ```

__Description__

Save defaults for a record type


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:default_values) <request body> -- The default values set
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
  
	  String record_type -- 
  

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

Get default values for a record type


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
  
	  String record_type -- 
  

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
"component_id":"F795773711N",
"title":"Digital Object Component Title: 7",
"digital_object":{ "ref":"/repositories/2/digital_objects/1"},
"position":10,
"has_unpublished_ancestor":true}' \
  "http://localhost:8089/repositories/2/digital_object_components"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components ```

__Description__

Create an Digital Object Component


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:digital_object_component) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Digital Object Components for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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
"component_id":"F795773711N",
"title":"Digital Object Component Title: 7",
"digital_object":{ "ref":"/repositories/2/digital_objects/1"},
"position":10,
"has_unpublished_ancestor":true}' \
  "http://localhost:8089/repositories/2/digital_object_components/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components/:id ```

__Description__

Update an Digital Object Component


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:digital_object_component) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get an Digital Object Component by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete a Digital Object Component


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Move existing Digital Object Components to become children of a Digital Object Component



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_object_components/1/accept_children?children=856263X695945&position=1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components/:id/accept_children ```

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




## Batch create several Digital Object Components as children of an existing Digital Object Component



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/digital_object_components/1/children"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_object_components/:id/children ```

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




## Get the children of an Digital Object Component



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_object_components/1/children"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_object_components/:id/children ```

__Description__

Get the children of an Digital Object Component


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Set the parent/position of an Digital Object Component in a tree


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer parent (Optional) -- The parent of this node in the tree
  
  
    
  
  
    
    
  
  
	  Integer position (Optional) -- The position of this node in the tree
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Suppress this record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  RESTHelpers::BooleanParam suppressed -- Suppression state
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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
"portion":"part",
"number":"79",
"extent_type":"terabytes",
"dimensions":"NN667I654",
"physical_details":"X47UDD"}],
"lang_materials":[{ "jsonmodel_type":"lang_material",
"notes":[],
"language_and_script":{ "jsonmodel_type":"language_and_script",
"language":"mos",
"script":"Gong"}}],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"file_versions":[{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"TTNEA",
"use_statement":"image-thumbnail",
"xlink_actuate_attribute":"other",
"xlink_show_attribute":"replace",
"file_format_name":"tiff",
"file_format_version":"PENEX",
"file_size_bytes":33,
"checksum":"E227YUT",
"checksum_method":"sha-384",
"publish":true}],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 6",
"digital_object_id":"48198RU731"}' \
  "http://localhost:8089/repositories/2/digital_objects"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects ```

__Description__

Create a Digital Object


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:digital_object) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Digital Objects for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a Digital Object


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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
"portion":"part",
"number":"79",
"extent_type":"terabytes",
"dimensions":"NN667I654",
"physical_details":"X47UDD"}],
"lang_materials":[{ "jsonmodel_type":"lang_material",
"notes":[],
"language_and_script":{ "jsonmodel_type":"language_and_script",
"language":"mos",
"script":"Gong"}}],
"dates":[],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"file_versions":[{ "jsonmodel_type":"file_version",
"is_representative":false,
"file_uri":"TTNEA",
"use_statement":"image-thumbnail",
"xlink_actuate_attribute":"other",
"xlink_show_attribute":"replace",
"file_format_name":"tiff",
"file_format_version":"PENEX",
"file_size_bytes":33,
"checksum":"E227YUT",
"checksum_method":"sha-384",
"publish":true}],
"restrictions":false,
"notes":[],
"linked_instances":[],
"title":"Digital Object Title: 6",
"digital_object_id":"48198RU731"}' \
  "http://localhost:8089/repositories/2/digital_objects/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id ```

__Description__

Update a Digital Object


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:digital_object) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Delete a Digital Object


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Move existing Digital Object components to become children of a Digital Object



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/accept_children?children=RFTKT&position=1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id/accept_children ```

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




## Batch create several Digital Object Components as children of an existing Digital Object



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/digital_objects/1/children"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id/children ```

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




## Publish a digital object and all its sub-records and components



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/publish"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id/publish ```

__Description__

Publish a digital object and all its sub-records and components


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Suppress this record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  RESTHelpers::BooleanParam suppressed -- Suppression state
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## Transfer this record to a different repository



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/digital_objects/1/transfer?target_repo=RHKS250"

```


__Endpoint__

```[:POST] /repositories/:repo_id/digital_objects/:id/transfer ```

__Description__

Transfer this record to a different repository


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  String target_repo -- The URI of the target repository
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- moved




## Get a Digital Object tree



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree ```

__Description__

Get a Digital Object tree


__Parameters__
<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Call the */tree/{root,waypoint,node} endpoints to traverse record trees.  See backend/app/model/large_tree.rb for further information.</p>
  
</aside>


  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- OK




## Fetch tree information for an Digital Object Component record within a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree/node?node_uri=GNDW936&published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree/node ```

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




## Fetch tree paths from the root record to Digital Object Components



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree/node_from_root?node_ids=1&published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree/node_from_root ```

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




## Fetch tree information for the top-level digital object record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree/root?published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree/root ```

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




## Fetch the record slice for a given tree waypoint



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/1/tree/waypoint?offset=1&parent_node=YG519Y994&published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/:id/tree/waypoint ```

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




## Get metadata for a Dublin Core export



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/dublin_core/1.:fmt/metadata"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata ```

__Description__

Get metadata for a Dublin Core export


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- The export metadata




## Get a Dublin Core representation of a Digital Object 



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/dublin_core/1.xml"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/dublin_core/:id.xml ```

__Description__

Get a Dublin Core representation of a Digital Object 


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- (:digital_object)




## Get metadata for a METS export



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/mets/1.:fmt/metadata"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata ```

__Description__

Get metadata for a METS export


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- The export metadata




## Get a METS representation of a Digital Object 



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/mets/1.xml?dmd=PKG410P"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/mets/:id.xml ```

__Description__

Get a METS representation of a Digital Object 


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  String dmd (Optional) -- DMD Scheme to use
  

__Returns__

  	200 -- (:digital_object)




## Get metadata for a MODS export



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/mods/1.:fmt/metadata"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata ```

__Description__

Get metadata for a MODS export


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- The export metadata




## Get a MODS representation of a Digital Object 



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/digital_objects/mods/1.xml"

```


__Endpoint__

```[:GET] /repositories/:repo_id/digital_objects/mods/:id.xml ```

__Description__

Get a MODS representation of a Digital Object 


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- (:digital_object)




## Create an Event



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"event",
"external_ids":[],
"external_documents":[],
"linked_agents":[{ "ref":"/agents/people/2",
"role":"requester"}],
"linked_records":[{ "ref":"/repositories/2/accessions/1",
"role":"transfer"}],
"date":{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"2000-09-14",
"end":"2000-09-14",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"A182652977F"},
"event_type":"cataloged"}' \
  "http://localhost:8089/repositories/2/events"

```


__Endpoint__

```[:POST] /repositories/:repo_id/events ```

__Description__

Create an Event


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:event) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Events for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- [(:event)]




## Update an Event



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"event",
"external_ids":[],
"external_documents":[],
"linked_agents":[{ "ref":"/agents/people/2",
"role":"requester"}],
"linked_records":[{ "ref":"/repositories/2/accessions/1",
"role":"transfer"}],
"date":{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"2000-09-14",
"end":"2000-09-14",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"A182652977F"},
"event_type":"cataloged"}' \
  "http://localhost:8089/repositories/2/events/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/events/:id ```

__Description__

Update an Event


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:event) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get an Event by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete an event record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Suppress this record from non-managers


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  RESTHelpers::BooleanParam suppressed -- Suppression state
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## Find Archival Objects by ref_id or component_id



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/find_by_id/archival_objects?ref_id=C773851513V&component_id=R881DC637&resolve[]=[record_types, to_resolve]"

```


__Endpoint__

```[:GET] /repositories/:repo_id/find_by_id/archival_objects ```

__Description__

Find Archival Objects by ref_id or component_id


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] ref_id (Optional) -- An archival object's Ref ID (param may be repeated)
  
  
    
  
  
    
    
  
  
	  [String] component_id (Optional) -- An archival object's component ID (param may be repeated)
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

__Returns__

  	200 -- JSON array of refs




## Find Digital Object Components by component_id



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/find_by_id/digital_object_components?component_id=424TL927Q&resolve[]=[record_types, to_resolve]"

```


__Endpoint__

```[:GET] /repositories/:repo_id/find_by_id/digital_object_components ```

__Description__

Find Digital Object Components by component_id


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] component_id (Optional) -- A digital object component's component ID (param may be repeated)
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

__Returns__

  	200 -- JSON array of refs




## Find Digital Objects by digital_object_id



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/find_by_id/digital_objects?digital_object_id=TIGO877&resolve[]=[record_types, to_resolve]"

```


__Endpoint__

```[:GET] /repositories/:repo_id/find_by_id/digital_objects ```

__Description__

Find Digital Objects by digital_object_id


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] digital_object_id (Optional) -- A digital object's digital object ID (param may be repeated)
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

__Returns__

  	200 -- JSON array of refs




## Find Resources by their identifiers



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/find_by_id/resources?identifier=921582L83382&resolve[]=[record_types, to_resolve]"

```


__Endpoint__

```[:GET] /repositories/:repo_id/find_by_id/resources ```

__Description__

Find Resources by their identifiers


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] identifier (Optional) -- A 4-part identifier expressed as a JSON array (of up to 4 strings) comprised of the id_0 to id_3 fields (though empty fields will be handled if not provided)
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

__Returns__

  	200 -- JSON array of refs




## Create a group within a repository



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 10",
"member_usernames":[],
"grants_permissions":[],
"group_code":"H158785A79"}' \
  "http://localhost:8089/repositories/2/groups"

```


__Endpoint__

```[:POST] /repositories/:repo_id/groups ```

__Description__

Create a group within a repository


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:group) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}

  	409 -- conflict




## Get a list of groups for a repository



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/groups?group_code=QCX644194"

```


__Endpoint__

```[:GET] /repositories/:repo_id/groups ```

__Description__

Get a list of groups for a repository


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  String group_code (Optional) -- Get groups by group code
  

__Returns__

  	200 -- [(:resource)]




## Update a group



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"group",
"description":"Description: 10",
"member_usernames":[],
"grants_permissions":[],
"group_code":"H158785A79"}' \
  "http://localhost:8089/repositories/2/groups/1?with_members=true"

```


__Endpoint__

```[:POST] /repositories/:repo_id/groups/:id ```

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




## Get a group by ID



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/groups/1?with_members=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/groups/:id ```

__Description__

Get a group by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  RESTHelpers::BooleanParam with_members -- If 'true' (the default) return the list of members with the group
  

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

Delete a group by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- (:group)

  	404 -- Not found




## Create a new job



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"job",
"status":"queued",
"job":{ "jsonmodel_type":"import_job",
"filenames":["SO837QA",
"LLX701T",
"C861898IT",
"Y260B145R"],
"import_type":"marcxml"}}' \
  "http://localhost:8089/repositories/2/jobs"

```


__Endpoint__

```[:POST] /repositories/:repo_id/jobs ```

__Description__

Create a new job


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:job) <request body> -- The job object
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Jobs for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Delete a Job


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a Job by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Cancel a Job


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a Job's log by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  RESTHelpers::NonNegativeInteger offset -- The byte offset of the log file to show
  

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

Get a list of Job's output files by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a Job's output file by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  Integer file_id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a Job's list of created URIs


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

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of all active Jobs for a Repository


__Parameters__

  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of all archived Jobs for a Repository


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

  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

List all supported import job types


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- A list of supported import types




## Create a new job and post input files



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/jobs_with_files?job={"jsonmodel_type"=>"job", "status"=>"queued", "job"=>{"jsonmodel_type"=>"import_job", "filenames"=>["SO837QA", "LLX701T", "C861898IT", "Y260B145R"], "import_type"=>"marcxml"}}&files=UploadFile"

```


__Endpoint__

```[:POST] /repositories/:repo_id/jobs_with_files ```

__Description__

Create a new job and post input files


__Parameters__

  
    
  
  
  
	  JSONModel(:job) job -- 
  
  
    
  
  
  
	  [RESTHelpers::UploadFile] files -- 
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Create a Preferences record


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:preference) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Preferences for a Repository and optionally a user


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  Integer user_id (Optional) -- The username to retrieve defaults for
  

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

Get a Preferences record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Update a Preferences record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:preference) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Delete a Preferences record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Get the default set of Preferences for a Repository and optionally a user



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/preferences/defaults?username=AH887RC"

```


__Endpoint__

```[:GET] /repositories/:repo_id/preferences/defaults ```

__Description__

Get the default set of Preferences for a Repository and optionally a user


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  String username (Optional) -- The username to retrieve defaults for
  

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

Create an RDE template


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:rde_template) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of RDE Templates


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get an RDE template record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Delete an RDE Template


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Require fields for a record type


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:required_fields) <request body> -- The fields required
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
  
	  String record_type -- 
  

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

Get required fields for a record type


__Parameters__

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
  
	  String record_type -- 
  

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}

  	400 -- {:error => (description of error)}




## Get export metadata for a Resource Description



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resource_descriptions/1.:fmt/metadata?fmt=864442169P755"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_descriptions/:id.:fmt/metadata ```

__Description__

Get export metadata for a Resource Description


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  String fmt (Optional) -- Format of the request
  

__Returns__

  	200 -- The export metadata




## Get an EAD representation of a Resource



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resource_descriptions/1.pdf?include_unpublished=true&include_daos=true&numbered_cs=true&print_pdf=true&ead3=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_descriptions/:id.pdf ```

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




## Get an EAD representation of a Resource



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resource_descriptions/1.xml?include_unpublished=true&include_daos=true&numbered_cs=true&print_pdf=true&ead3=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_descriptions/:id.xml ```

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




## Get export metadata for Resource labels



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resource_labels/1.:fmt/metadata"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_labels/:id.:fmt/metadata ```

__Description__

Get export metadata for Resource labels


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- The export metadata




## Get a tsv list of printable labels for a Resource



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resource_labels/1.tsv"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resource_labels/:id.tsv ```

__Description__

Get a tsv list of printable labels for a Resource


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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
"number":"2",
"extent_type":"cassettes",
"dimensions":"255IHVA",
"physical_details":"QIH379D"}],
"lang_materials":[{ "jsonmodel_type":"lang_material",
"notes":[],
"language_and_script":{ "jsonmodel_type":"language_and_script",
"language":"arw",
"script":"Rohg"}}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"2002-03-14",
"end":"2002-03-14",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"BJ48AW"},
{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"2007-11-17",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"EFHXG"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"WKESU",
"description":"E11470823W"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"mixed_materials",
"sub_container":{ "jsonmodel_type":"sub_container",
"top_container":{ "ref":"/repositories/2/top_containers/5"},
"type_2":"reel",
"indicator_2":"874NQ177516",
"type_3":"folder",
"indicator_3":"LUL337435"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>4</emph>",
"id_0":"939OQTU",
"level":"item",
"finding_aid_date":"L667714274C",
"finding_aid_series_statement":"256235HWR",
"finding_aid_language":"bua",
"finding_aid_script":"Lana",
"finding_aid_note":"H755G946R",
"ead_location":"116451DKA"}' \
  "http://localhost:8089/repositories/2/resources"

```


__Endpoint__

```[:POST] /repositories/:repo_id/resources ```

__Description__

Create a Resource


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:resource) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of Resources for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a Resource


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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
"number":"2",
"extent_type":"cassettes",
"dimensions":"255IHVA",
"physical_details":"QIH379D"}],
"lang_materials":[{ "jsonmodel_type":"lang_material",
"notes":[],
"language_and_script":{ "jsonmodel_type":"language_and_script",
"language":"arw",
"script":"Rohg"}}],
"dates":[{ "jsonmodel_type":"date",
"date_type":"bulk",
"label":"creation",
"begin":"2002-03-14",
"end":"2002-03-14",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"BJ48AW"},
{ "jsonmodel_type":"date",
"date_type":"single",
"label":"creation",
"begin":"2007-11-17",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"EFHXG"}],
"external_documents":[],
"rights_statements":[],
"linked_agents":[],
"is_slug_auto":true,
"restrictions":false,
"revision_statements":[{ "jsonmodel_type":"revision_statement",
"date":"WKESU",
"description":"E11470823W"}],
"instances":[{ "jsonmodel_type":"instance",
"is_representative":false,
"instance_type":"mixed_materials",
"sub_container":{ "jsonmodel_type":"sub_container",
"top_container":{ "ref":"/repositories/2/top_containers/5"},
"type_2":"reel",
"indicator_2":"874NQ177516",
"type_3":"folder",
"indicator_3":"LUL337435"}}],
"deaccessions":[],
"related_accessions":[],
"classifications":[],
"notes":[],
"title":"Resource Title: <emph render='italic'>4</emph>",
"id_0":"939OQTU",
"level":"item",
"finding_aid_date":"L667714274C",
"finding_aid_series_statement":"256235HWR",
"finding_aid_language":"bua",
"finding_aid_script":"Lana",
"finding_aid_note":"H755G946R",
"ead_location":"116451DKA"}' \
  "http://localhost:8089/repositories/2/resources/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id ```

__Description__

Update a Resource


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:resource) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Delete a Resource


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Move existing Archival Objects to become children of a Resource



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/accept_children?children=AQIT943&position=1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id/accept_children ```

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




## Batch create several Archival Objects as children of an existing Resource



  
    
  
  
    
  
  
    
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/resources/1/children"

```


__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id/children ```

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




## Get a list of record types in the graph of a resource



  
    
  
  
    
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/models_in_graph"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/models_in_graph ```

__Description__

Get a list of record types in the graph of a resource


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get the list of URIs of this published resource and all published archival objects contained within.Ordered by tree order (i.e. if you fully expanded the record tree and read from top to bottom)


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Publish a resource and all its sub-records and components


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Suppress this record


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  RESTHelpers::BooleanParam suppressed -- Suppression state
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}




## Get Top Containers linked to a published resource and published archival ojbects contained within.



  
    
  
  
    
  
  
    
  
  
  
    
      
    
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/top_containers?resolve[]=[record_types, to_resolve]"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/top_containers ```

__Description__

Get Top Containers linked to a published resource and published archival ojbects contained within.


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

__Returns__

  	200 -- a list of linked top containers

  	404 -- Not found




## Transfer this record to a different repository



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/resources/1/transfer?target_repo=KBVKL"

```


__Endpoint__

```[:POST] /repositories/:repo_id/resources/:id/transfer ```

__Description__

Transfer this record to a different repository


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
  
	  String target_repo -- The URI of the target repository
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- moved




## Get a Resource tree



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree?limit_to=ITJ723D"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree ```

__Description__

Get a Resource tree


__Parameters__
<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Call the */tree/{root,waypoint,node} endpoints to traverse record trees.  See backend/app/model/large_tree.rb for further information.</p>
  
</aside>


  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  String limit_to (Optional) -- An Archival Object URI or 'root'
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- OK




## Fetch tree information for an Archival Object record within a tree



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree/node?node_uri=K132TY698&published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree/node ```

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




## Fetch tree paths from the root record to Archival Objects



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree/node_from_root?node_ids=1&published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree/node_from_root ```

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




## Fetch tree information for the top-level resource record



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree/root?published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree/root ```

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




## Fetch the record slice for a given tree waypoint



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/1/tree/waypoint?offset=1&parent_node=WCY583E&published_only=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/:id/tree/waypoint ```

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




## Get metadata for a MARC21 export



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/marc21/1.:fmt/metadata?include_unpublished_marc=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/marc21/:id.:fmt/metadata ```

__Description__

Get metadata for a MARC21 export


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  RESTHelpers::BooleanParam include_unpublished_marc (Optional) -- Include unpublished notes
  

__Returns__

  	200 -- The export metadata




## Get a MARC 21 representation of a Resource



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/resources/marc21/1.xml?include_unpublished_marc=true"

```


__Endpoint__

```[:GET] /repositories/:repo_id/resources/marc21/:id.xml ```

__Description__

Get a MARC 21 representation of a Resource


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  RESTHelpers::BooleanParam include_unpublished_marc (Optional) -- Include unpublished notes
  

__Returns__

  	200 -- (:resource)




## Search this repository



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"42213DSX"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"VRA932N"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"EW730YL"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"N711542B834"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"RKQCW"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"TP569TA"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"F28198134061"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"515158EHP"' \
  "http://localhost:8089/repositories/2/search?q=42213DSX&aq=["Example Missing"]&type=VRA932N&sort=EW730YL&facet=N711542B834&facet_mincount=1&filter=["Example Missing"]&exclude=RKQCW&hl=true&root_record=TP569TA&dt=F28198134061&fields=515158EHP"
  

```


__Endpoint__

```[:GET, :POST] /repositories/:repo_id/search ```

__Description__

Search this repository


__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
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
  
  
    
  
  
    
    
  
  
	  [String] fields (Optional) -- The list of fields to include in the results
  

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
"indicator":"73516PYH",
"type":"box",
"barcode":"228ad3845f336224fe31d73a15e2a656",
"ils_holding_id":"J501MM0",
"ils_item_id":"564EHTB",
"exported_to_ils":"2020-11-11T13:18:16-05:00"}' \
  "http://localhost:8089/repositories/2/top_containers"

```


__Endpoint__

```[:POST] /repositories/:repo_id/top_containers ```

__Description__

Create a top container


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:top_container) <request body> -- The record to create
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a list of TopContainers for a Repository


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

  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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
"indicator":"73516PYH",
"type":"box",
"barcode":"228ad3845f336224fe31d73a15e2a656",
"ils_holding_id":"J501MM0",
"ils_item_id":"564EHTB",
"exported_to_ils":"2020-11-11T13:18:16-05:00"}' \
  "http://localhost:8089/repositories/2/top_containers/1"

```


__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/:id ```

__Description__

Update a top container


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:top_container) <request body> -- The updated record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a top container by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Delete a top container


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- deleted




## Update container profile for a batch of top containers



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/top_containers/batch/container_profile?ids=1&container_profile_uri=465F871Y726"

```


__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/batch/container_profile ```

__Description__

Update container profile for a batch of top containers


__Parameters__

  
    
  
  
  
	  [Integer] ids -- 
  
  
    
  
  
  
	  String container_profile_uri -- The uri of the container profile
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}




## Update ils_holding_id for a batch of top containers



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/top_containers/batch/ils_holding_id?ids=1&ils_holding_id=379E660AT"

```


__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/batch/ils_holding_id ```

__Description__

Update ils_holding_id for a batch of top containers


__Parameters__

  
    
  
  
  
	  [Integer] ids -- 
  
  
    
  
  
  
	  String ils_holding_id -- Value to set for ils_holding_id
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Update location for a batch of top containers
This route takes the `ids` of one or more containers, and associates the containers
with the location referenced by `location_uri`.


__Parameters__

  
    
  
  
  
	  [Integer] ids -- 
  
  
    
  
  
  
	  String location_uri -- The uri of the location
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}




## Bulk update barcodes



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"W436CQA"' \
  "http://localhost:8089/repositories/2/top_containers/bulk/barcodes"

```


__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/bulk/barcodes ```

__Description__

Bulk update barcodes


__Parameters__

  
    
  
  
    
    
  
  
	  String <request body> -- JSON string containing barcode data {uri=>barcode}
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}




## Bulk update locations



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"RULV802"' \
  "http://localhost:8089/repositories/2/top_containers/bulk/locations"

```


__Endpoint__

```[:POST] /repositories/:repo_id/top_containers/bulk/locations ```

__Description__

Bulk update locations


__Parameters__

  
    
  
  
    
    
  
  
	  String <request body> -- JSON string containing location data {container_uri=>location_uri}
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}




## Search for top containers



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/repositories/2/top_containers/search?q=E39I394717&aq=["Example Missing"]&type=O207NBV&sort=LNF672214&facet=RSU495813&facet_mincount=1&filter=["Example Missing"]&exclude=D111WNL&hl=true&root_record=506MVRV&dt=586DPT352&fields=SGN650I"

```


__Endpoint__

```[:GET] /repositories/:repo_id/top_containers/search ```

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
  
  
    
  
  
    
    
  
  
	  [String] fields (Optional) -- The list of fields to include in the results
  

__Returns__

  	200 -- [(:top_container)]




## Transfer this record to a different repository



  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/repositories/2/transfer?target_repo=XVFKH"

```


__Endpoint__

```[:POST] /repositories/:repo_id/transfer ```

__Description__

Transfer this record to a different repository


__Parameters__

  
    
  
  
  
	  String target_repo -- The URI of the target repository
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

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

Get a user's details including their groups for the current repository


__Parameters__

  
    
  
  
  
	  Integer id -- The username id to fetch
  
  
    
  
  
    
    
  
  
	  Integer repo_id -- The Repository ID -- The Repository must exist
  

__Returns__

  	200 -- (:user)




## Create a Repository with an agent representation



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"repository_with_agent",
"repository":{ "jsonmodel_type":"repository",
"name":"Description: 12",
"is_slug_auto":true,
"repo_code":"ASPACE REPO 3 -- 228764",
"org_code":"GIP345R",
"image_url":"http://www.example-14.com",
"url":"http://www.example-15.com",
"country":"US"},
"agent_representation":{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number_type":"home",
"number":"0046 88024 3736",
"ext":"898M845H664"}],
"name":"Name Number 15",
"address_2":"I40753406H",
"address_3":"856N812170V",
"post_code":"JPQ102T",
"fax":"X866G4T",
"email":"KLG434589"}],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"1988-01-13",
"end":"1988-01-13",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"MW458FW"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"primary_name":"Name Number 14",
"subordinate_name_1":"691RWEE",
"subordinate_name_2":"529439586SG",
"number":"FKJBN",
"sort_name":"SORT l - 11",
"dates":"EB196129411",
"qualifier":"816922LEX",
"authority_id":"http://www.example-16.com",
"source":"ingest"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}}' \
  "http://localhost:8089/repositories/with_agent"

```


__Endpoint__

```[:POST] /repositories/with_agent ```

__Description__

Create a Repository with an agent representation


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:repository_with_agent) <request body> -- The record to create
  

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

Get a Repository by ID, including its agent representation


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  

__Returns__

  	200 -- (:repository_with_agent)

  	404 -- Not found




## Update a repository with an agent representation



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"repository_with_agent",
"repository":{ "jsonmodel_type":"repository",
"name":"Description: 12",
"is_slug_auto":true,
"repo_code":"ASPACE REPO 3 -- 228764",
"org_code":"GIP345R",
"image_url":"http://www.example-14.com",
"url":"http://www.example-15.com",
"country":"US"},
"agent_representation":{ "jsonmodel_type":"agent_corporate_entity",
"agent_contacts":[{ "jsonmodel_type":"agent_contact",
"telephones":[{ "jsonmodel_type":"telephone",
"number_type":"home",
"number":"0046 88024 3736",
"ext":"898M845H664"}],
"name":"Name Number 15",
"address_2":"I40753406H",
"address_3":"856N812170V",
"post_code":"JPQ102T",
"fax":"X866G4T",
"email":"KLG434589"}],
"linked_agent_roles":[],
"external_documents":[],
"notes":[],
"used_within_repositories":[],
"used_within_published_repositories":[],
"dates_of_existence":[{ "jsonmodel_type":"date",
"date_type":"range",
"label":"existence",
"begin":"1988-01-13",
"end":"1988-01-13",
"certainty":"inferred",
"era":"ce",
"calendar":"gregorian",
"expression":"MW458FW"}],
"is_slug_auto":true,
"names":[{ "jsonmodel_type":"name_corporate_entity",
"use_dates":[],
"authorized":false,
"is_display_name":false,
"sort_name_auto_generate":true,
"rules":"aacr",
"primary_name":"Name Number 14",
"subordinate_name_1":"691RWEE",
"subordinate_name_2":"529439586SG",
"number":"FKJBN",
"sort_name":"SORT l - 11",
"dates":"EB196129411",
"qualifier":"816922LEX",
"authority_id":"http://www.example-16.com",
"source":"ingest"}],
"related_agents":[],
"agent_type":"agent_corporate_entity"}}' \
  "http://localhost:8089/repositories/with_agent/1"

```


__Endpoint__

```[:POST] /repositories/with_agent/:id ```

__Description__

Update a repository with an agent representation


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:repository_with_agent) <request body> -- The updated record
  

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

Get all ArchivesSpace schemas


__Parameters__


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

Get an ArchivesSpace schema


__Parameters__

  
    
  
  
  
	  String schema -- Schema name to retrieve
  

__Returns__

  	200 -- ArchivesSpace (:schema)

  	404 -- Schema not found




## Search this archive



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"128122JNY"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"480921VPV"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"671K736HM"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"QHKOD"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"210Y484M39"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"HED575249"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"295408993E1"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"234129B965R"' \
  "http://localhost:8089/search?q=128122JNY&aq=["Example Missing"]&type=480921VPV&sort=671K736HM&facet=QHKOD&facet_mincount=1&filter=["Example Missing"]&exclude=210Y484M39&hl=true&root_record=HED575249&dt=295408993E1&fields=234129B965R"
  

```


__Endpoint__

```[:GET, :POST] /search ```

__Description__

Search this archive


__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
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
  
  
    
  
  
    
    
  
  
	  [String] fields (Optional) -- The list of fields to include in the results
  

__Returns__

  	200 -- 




## Search across Location Profiles



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
# return first 10 records
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/search/location_profile?q=W70644385A&aq=["Example Missing"]&type=261W832205958&sort=633HOT462&facet=F572EDV&facet_mincount=1&filter=["Example Missing"]&exclude=YLDHK&hl=true&root_record=MPLKS&dt=KAFGC&fields=949NSI203?page=1&page_size=10"

```


__Endpoint__

```[:GET] /search/location_profile ```

__Description__

Search across Location Profiles


__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
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
  
  
    
  
  
    
    
  
  
	  [String] fields (Optional) -- The list of fields to include in the results
  

__Returns__

  	200 -- 




## Find the tree view for a particular archival record



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/search/published_tree?node_uri=757626TNB"

```


__Endpoint__

```[:GET] /search/published_tree ```

__Description__

Find the tree view for a particular archival record


__Parameters__

  
    
  
  
  
	  String node_uri -- The URI of the archival record to find the tree view for
  

__Returns__

  	200 -- OK

  	404 -- Not found




## Return the counts of record types of interest by repository



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"G652RDG"' \
  "http://localhost:8089/search/record_types_by_repository?record_types=G652RDG&repo_uri=OU448YX"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"OU448YX"' \
  "http://localhost:8089/search/record_types_by_repository?record_types=G652RDG&repo_uri=OU448YX"
  

```


__Endpoint__

```[:GET, :POST] /search/record_types_by_repository ```

__Description__

Return the counts of record types of interest by repository


__Parameters__

  
    
  
  
  
	  [String] record_types -- The list of record types to tally
  
  
    
  
  
    
    
  
  
	  String repo_uri (Optional) -- An optional repository URI.  If given, just return counts for the single repository
  

__Returns__

  	200 -- If repository is given, returns a map like {'record_type' => <count>}.  Otherwise, {'repo_uri' => {'record_type' => <count>}}




## Return a set of records by URI



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
    
  
  

  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"153215F972N"' \
  "http://localhost:8089/search/records?uri=153215F972N&resolve[]=[record_types, to_resolve]"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"292NQ285662"' \
  "http://localhost:8089/search/records?uri=153215F972N&resolve[]=[record_types, to_resolve]"
  

```


__Endpoint__

```[:GET, :POST] /search/records ```

__Description__

Return a set of records by URI


__Parameters__

  
    
  
  
  
	  [String] uri -- The list of record URIs to fetch
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- The list of result fields to resolve (if any)
  

__Returns__

  	200 -- a JSON map of records




## Search across repositories



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"V824324LW"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"420R435Q330"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"984H69PU"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"WMILJ"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"X882251422C"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"T657ODR"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"AQ829MR"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"KNR72822"' \
  "http://localhost:8089/search/repositories?q=V824324LW&aq=["Example Missing"]&type=420R435Q330&sort=984H69PU&facet=WMILJ&facet_mincount=1&filter=["Example Missing"]&exclude=X882251422C&hl=true&root_record=T657ODR&dt=AQ829MR&fields=KNR72822"
  

```


__Endpoint__

```[:GET, :POST] /search/repositories ```

__Description__

Search across repositories


__Parameters__
<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
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
  
  
    
  
  
    
    
  
  
	  [String] fields (Optional) -- The list of fields to include in the results
  

__Returns__

  	200 -- 




## Search across subjects



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
  
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"MC812YM"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"U576461CX"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"G274FHN"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"Y677IF229"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"1"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '["Example Missing"]' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"337QNUF"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"BooleanParam"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"483N653SW"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"J594294L722"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
    
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '"235RFEY"' \
  "http://localhost:8089/search/subjects?q=MC812YM&aq=["Example Missing"]&type=U576461CX&sort=G274FHN&facet=Y677IF229&facet_mincount=1&filter=["Example Missing"]&exclude=337QNUF&hl=true&root_record=483N653SW&dt=J594294L722&fields=235RFEY"
  

```


__Endpoint__

```[:GET, :POST] /search/subjects ```

__Description__

Search across subjects


__Parameters__
<aside class="warning">
  This endpoint is deprecated, and may be removed from a future release of ArchivesSpace.
  
    <p>Deprecated in favor of calling the general search endpoint with an  optional type parameter. For example: /repositories/:repo_id/search?type[]=subject</p>
  
</aside>

<aside class="notice">
This endpoint is paginated. :page is required
<ul>
  <li>Integer page &ndash; The page set to be returned</li>
  <li>Integer page_size &ndash; The size of the set to be returned ( Optional. default set in AppConfig )</li>
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
  
  
    
  
  
    
    
  
  
	  [String] fields (Optional) -- The list of fields to include in the results
  

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

Find the record given the slug, return id, repo_id, and table name


__Parameters__

  
    
  
  
  
	  l s -- u
  
  
    
  
  
  
	  o c -- n
  
  
    
  
  
  
	  c a -- t
  

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

Get a Location by ID


__Parameters__


__Returns__

  	200 -- Location building data as JSON




## Calculate how many containers will fit in locations for a given building



  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/space_calculator/by_building?container_profile_uri=965BQSI&building=UN204T231&floor=940Q314RJ&room=635HNW159&area=72SPOT"

```


__Endpoint__

```[:GET] /space_calculator/by_building ```

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




## Calculate how many containers will fit in a list of locations



  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/space_calculator/by_location?container_profile_uri=GO677719990&location_uris=GCUYA"

```


__Endpoint__

```[:GET] /space_calculator/by_location ```

__Description__

Calculate how many containers will fit in a list of locations


__Parameters__

  
    
  
  
  
	  String container_profile_uri -- The uri of the container profile
  
  
    
  
  
  
	  [String] location_uris -- A list of location uris to calculate space for
  

__Returns__

  	200 -- Calculation results




## Create a Subject



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"subject",
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
"source":"lcsh"}' \
  "http://localhost:8089/subjects"

```


__Endpoint__

```[:POST] /subjects ```

__Description__

Create a Subject


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:subject) <request body> -- The record to create
  

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

Get a list of Subjects


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
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"subject",
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
"source":"lcsh"}' \
  "http://localhost:8089/subjects/1"

```


__Endpoint__

```[:POST] /subjects/:id ```

__Description__

Update a Subject


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:subject) <request body> -- The updated record
  

__Returns__

  	200 -- {:status => "Updated", :id => (id of updated object)}




## Get a Subject by ID



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/subjects/1"

```


__Endpoint__

```[:GET] /subjects/:id ```

__Description__

Get a Subject by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  

__Returns__

  	200 -- (:subject)




## Delete a Subject



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -X DELETE \
  "http://localhost:8089/subjects/1"

```


__Endpoint__

```[:DELETE] /subjects/:id ```

__Description__

Delete a Subject


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  

__Returns__

  	200 -- deleted




## Get a list of Terms matching a prefix



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/terms?q=696426I281G"

```


__Endpoint__

```[:GET] /terms ```

__Description__

Get a list of Terms matching a prefix


__Parameters__

  
    
  
  
  
	  String q -- The prefix to match
  

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

Get a stream of updated records


__Parameters__

  
    
  
  
    
    
  
  
	  Integer last_sequence (Optional) -- The last sequence number seen
  
  
    
  
  
    
    
  
  
	  [String] resolve (Optional) -- A list of references to resolve and embed in the response
  

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

Refresh the list of currently known edits


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:active_edits) <request body> -- The list of active edits
  

__Returns__

  	200 -- A list of records, the user editing it and the lock version for each




## Create a local user



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_admin":false,
"username":"username_1",
"name":"Name Number 16"}' \
  "http://localhost:8089/users?password=924WY481X&groups=PT546632949"

```


__Endpoint__

```[:POST] /users ```

__Description__

Create a local user


__Parameters__

  
    
  
  
  
	  String password -- The user's password
  
  
    
  
  
    
    
  
  
	  [String] groups (Optional) -- Array of groups URIs to assign the user to
  
  
    
  
  
    
    
  
  
	  JSONModel(:user) <request body> -- The record to create
  

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

Get a list of users


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

Get a user's details (including their current permissions)


__Parameters__

  
    
  
  
  
	  Integer id -- The username id to fetch
  

__Returns__

  	200 -- (:user)




## Update a user's account



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"user",
"groups":[],
"is_admin":false,
"username":"username_1",
"name":"Name Number 16"}' \
  "http://localhost:8089/users/1?password=KYP145L"

```


__Endpoint__

```[:POST] /users/:id ```

__Description__

Update a user's account


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  String password (Optional) -- The user's password
  
  
    
  
  
    
    
  
  
	  JSONModel(:user) <request body> -- The updated record
  

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

Delete a user


__Parameters__

  
    
  
  
  
	  Integer id -- The user to delete
  

__Returns__

  	200 -- deleted




## Update a user's groups



  
    
  
  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/users/1/groups?groups=363PCVE&remove_groups=true"

```


__Endpoint__

```[:POST] /users/:id/groups ```

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




## Become a different user



  
    
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/users/1/become-user"

```


__Endpoint__

```[:POST] /users/:username/become-user ```

__Description__

Become a different user


__Parameters__

  
    
  
  
  
	  Username username -- The username to become
  

__Returns__

  	200 -- Accepted

  	404 -- User not found




## Log in



  
    
  
  
    
  
  
    
  
  
  
    
      
        
      
        
  
    
      
        
      
        
  
  

  
    
  
  
    
  
  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d 'Example Missing' \
  "http://localhost:8089/users/1/login?password=VVYF567&expiring=true"

```


__Endpoint__

```[:POST] /users/:username/login ```

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




## Get a list of system users



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/users/complete?query=223WKED"

```


__Endpoint__

```[:GET] /users/complete ```

__Description__

Get a list of system users


__Parameters__

  
    
  
  
  
	  String query -- A prefix to search for
  

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

Get the currently logged in user


__Parameters__


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

Get the ArchivesSpace application version


__Parameters__


__Returns__

  	200 -- ArchivesSpace (version)




## Create a Vocabulary



  
    
  

  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"vocabulary",
"terms":[],
"name":"Vocabulary 4 - 2020-11-11 13:18:16 -0500",
"ref_id":"vocab_ref_4 - 2020-11-11 13:18:16 -0500"}' \
  "http://localhost:8089/vocabularies"

```


__Endpoint__

```[:POST] /vocabularies ```

__Description__

Create a Vocabulary


__Parameters__

  
    
  
  
    
    
  
  
	  JSONModel(:vocabulary) <request body> -- The record to create
  

__Returns__

  	200 -- {:status => "Created", :id => (id of created object), :warnings => {(warnings)}}




## Get a list of Vocabularies



  
    
  
  
  
    
      
        
      
        
  
  

  
    
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  "http://localhost:8089/vocabularies?ref_id=E471536W247"

```


__Endpoint__

```[:GET] /vocabularies ```

__Description__

Get a list of Vocabularies


__Parameters__

  
    
  
  
    
    
  
  
	  String ref_id (Optional) -- An alternate, externally-created ID for the vocabulary
  

__Returns__

  	200 -- [(:vocabulary)]




## Update a Vocabulary



  
    
  
  
    
  

  
    
  
  
    
  
  
  
```shell
curl -H "X-ArchivesSpace-Session: $SESSION" \
  -d '{ "jsonmodel_type":"vocabulary",
"terms":[],
"name":"Vocabulary 4 - 2020-11-11 13:18:16 -0500",
"ref_id":"vocab_ref_4 - 2020-11-11 13:18:16 -0500"}' \
  "http://localhost:8089/vocabularies/1"

```


__Endpoint__

```[:POST] /vocabularies/:id ```

__Description__

Update a Vocabulary


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  
  
    
  
  
    
    
  
  
	  JSONModel(:vocabulary) <request body> -- The updated record
  

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

Get a Vocabulary by ID


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  

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

Get a list of Terms for a Vocabulary


__Parameters__

  
    
  
  
  
	  Integer id -- The ID of the record
  

__Returns__

  	200 -- [(:term)]




# Routes by URI

<p>An index of routes available in the ArchivesSpace API, alphabetically by URI.</p>

<table>
  <thead>></thead>
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
        <td><a href="#suppress-this-record">/repositories/:repo_id/archival_objects/:id/suppressed</a></td>
        <td>POST</td>
        <td>Suppress this record</td>
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
        <td>Get a Dublin Core representation of a Digital Object </td>
      </tr>
    
      <tr>
        <td><a href="#get-metadata-for-a-mets-export">/repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata</a></td>
        <td>GET</td>
        <td>Get metadata for a METS export</td>
      </tr>
    
      <tr>
        <td><a href="#get-a-mets-representation-of-a-digital-object">/repositories/:repo_id/digital_objects/mets/:id.xml</a></td>
        <td>GET</td>
        <td>Get a METS representation of a Digital Object </td>
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
        <td><a href="#get-an-ead-representation-of-a-resource">/repositories/:repo_id/resource_descriptions/:id.pdf</a></td>
        <td>GET</td>
        <td>Get an EAD representation of a Resource</td>
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
