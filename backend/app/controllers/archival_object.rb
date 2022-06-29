class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/archival_objects')
    .description("Create an Archival Object")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" -d '{'jsonmodel_type': 'archival_object',
                                                         'publish': True,
                                                         'external_ids': [],
                                                         'subjects': [], 
                                                         'linked_events': [],
                                                         'extents': [{'number': '2',
                                                                      'portion': 'whole',
                                                                      'extent_type': 'folder(s)',
                                                                      'jsonmodel_type': 'extent'}],
                                                         'lang_materials': [],
                                                         'dates': [
                                                             {'expression': '1927, 1929',
                                                              'begin': '1927',
                                                              'end': '1929',
                                                              'date_type': 'inclusive',
                                                              'label': 'creation',
                                                              'jsonmodel_type': 'date'}],
                                                         'external_documents': [],
                                                         'rights_statements': [],
                                                         'linked_agents': [],
                                                         'is_slug_auto': True,
                                                         'restrictions_apply': False,
                                                         'ancestors': [],
                                                         'instances': [],
                                                         'notes': [],
                                                         'ref_id': "20029191", 
                                                         'level': 'file',
                                                         'title': 'Archival Object title',
                                                         'resource': {'ref': '/repositories/2/resources/5783'}' // 
        "http://localhost:8089/repositories/2/archival_objects"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
  
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
  
        client.authorize()  # authorizes the client
  
        new_ao = {'jsonmodel_type': 'archival_object',
                   'publish': True,
                   'external_ids': [],
                   'subjects': [], 
                   'linked_events': [],
                   'extents': [{'number': '2',
                                'portion': 'whole',
                                'extent_type': 'folder(s)',
                                'jsonmodel_type': 'extent'}],
                   'lang_materials': [],
                   'dates': [
                       {'expression': '1927, 1929',
                        'begin': '1927',
                        'end': '1929',
                        'date_type': 'inclusive',
                        'label': 'creation',
                        'jsonmodel_type': 'date'}],
                   'external_documents': [],
                   'rights_statements': [],
                   'linked_agents': [],
                   'is_slug_auto': True,
                   'restrictions_apply': False,
                   'ancestors': [],
                   'instances': [],
                   'notes': [],
                   'ref_id': "20029191",  # Can leave this out
                   'level': 'file',
                   'title': 'Archival Object title',
                   'resource': {'ref': '/repositories/2/resources/5783'}
                   }
        # This is a sample archival object that meets the minimum requirements. Make sure for the resource['ref'] value
        # to replace the 2 with the repository ID and 5783 with the resource ID. Find these in the URI of the resource 
        # in the staff interface
  
        create_ao = client.post('repositories/2/archival_objects', json=new_ao)
        # Replace 2 for your repository ID. Find this in the URI of your resource in the staff interface
  
        print(create_ao.json())
        # Output (dictionary): {'status': 'Created', 'id': 707459, 'lock_version': 0, 'stale': True, //
        # 'uri': '/repositories/2/archival_objects/707459', 'warnings': []}
      PYTHON
    end
    .params(["archival_object", JSONModel(:archival_object), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(ArchivalObject, params[:archival_object])
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id')
    .description("Update an Archival Object")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" -d '{"jsonmodel_type": "archival_object", 
                                                         "publish": true, 
                                                         "external_ids": [], 
                                                         "subjects": [], 
                                                         "linked_events": [], 
                                                         "extents": [{"number": "2", 
                                                                      "portion": "whole", 
                                                                      "extent_type": "folder(s)", 
                                                                      "jsonmodel_type": "extent"}], 
                                                         "lang_materials": [], 
                                                         "dates": [{"expression": "1927, 1929",
                                                                    "begin": "1927", 
                                                                    "end": "1929", 
                                                                    "date_type": "inclusive", 
                                                                    "label": "creation", 
                                                                    "jsonmodel_type": "date"}], 
                                                         "external_documents": [], 
                                                         "rights_statements": [], 
                                                         "linked_agents": [], 
                                                         "is_slug_auto": true, 
                                                         "restrictions_apply": false, 
                                                         "ancestors": [], 
                                                         "instances": [], 
                                                         "notes": [], 
                                                         "ref_id": "20029191", 
                                                         "level": "file", 
                                                         "title": "New title", 
                                                         "resource": {"ref": "/repositories/2/resources/5783"}}' //
        "http://localhost:8089/repositories/2/archival_objects"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
  
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
  
        client.authorize()  # authorizes the client
  
        original_ao = client.get("/repositories/2/archival_objects/707460").json()
        # First, get the json formatted archival object you want to update. Replace 2 with your repository ID and 
        # 707460 with the archival object ID as part of the URI for the object. You can find the URI when viewing the 
        # object in the ArchivesSpace staff interface in the Basic Information section.
  
        new_ao = original_ao
        new_ao["title"] = "New title"
        # Copy the original archival object json value and assign it to a new variable. Then updated whichever field
        # you need to. To see what fields you can change, do print(original_ao.json())
  
        update_ao = client.post("/repositories/2/archival_objects/707460", json=new_ao)
        # To send the updated archival object json to ArchivesSpace, input the URI of the archival object by replacing
        # the 2 with the repository ID and the 707460 with the archival object ID. Then pass new_ao to the json 
        # parameter
  
        print(update_ao.json())
        # Output (dictionary): {'status': 'Updated', 'id': 707460, 'lock_version': 3, 'stale': True, //
        # 'uri': '/repositories/2/archival_objects/707460', 'warnings': []}
      PYTHON
    end
    .params(["id", :id],
            ["archival_object", JSONModel(:archival_object), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(ArchivalObject, params[:id], params[:archival_object])
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id/parent')
    .description("Set the parent/position of an Archival Object in a tree")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        -d "parent=707458&position=2" "http://localhost:8089/repositories/2/archival_objects/707460/parent"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
  
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
  
        client.authorize()  # authorizes the client
  
        set_child_position = client.post("/repositories/2/archival_objects/707460/parent", params={"parent": 707458, 
                                                                                                   "position": 2})
        # Set the URI to the object that you want moved as a child. In this case, we are moving object 707460 to be the 
        # child of object 707458. In the URI string, replace the 2 with your repository ID and 707460 with the archival
        # object ID found in the URI. You can find both the repository ID and the archival object ID in the URI on the 
        # bottom right of the Basic Information section of the archival object page in the staff interface. Don't forget
        #  to add /parent to the end of the string. Set the "parent" as the archival object ID of the parent you want 
        # for the child and set the "position" as where in list of children you want that child placed (out of 15 
        # children, I want it in position 2 of 15)
  
        print(set_child_position.json())
        # Output (dictionary): {'status': 'Updated', 'id': 707460, 'lock_version': 3, 'stale': None}
      PYTHON
    end
    .params(["id", :id],
            ["parent", Integer, "The parent ID of this node in the tree", :optional => true],
            ["position", Integer, "The position of this node in the tree", :optional => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .no_data(true)
    .returns([200, :updated],
             [400, :error]) \
  do
    obj = ArchivalObject.get_or_die(params[:id])
    obj.set_parent_and_position(params[:parent], params[:position])

    updated_response(obj)
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:id')
    .description("Get an Archival Object by ID")
    .example("shell") do
    <<~SHELL
      curl -s -F password="admin" "http://localhost:8089/users/admin/login"
      set SESSION="session_id"
      curl -H "X-ArchivesSpace-Session: $SESSION" //
      "http://localhost:8089/repositories/2/archival_objects/48"
    SHELL
  end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
  
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
  
        client.authorize()  # authorizes the client
  
        archival_object = client.get("/repositories/2/archival_objects/48")
        # Replace 2 for your repository ID and 48 with your archival object ID. Find these in the URI of your archival 
        # object on the bottom right of the Basic Information section in the staff interface
  
        print(archival_object.json())
        # Output (dictionary): {"lock_version": 0, "position": 0, "publish": true, "ref_id": "ref01_uqj", //
        # "title": "Archival Object",...}
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:archival_object)"],
             [404, "Not found"]) \
  do
    json = ArchivalObject.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:id/children')
    .description("Get the children of an Archival Object")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/2/archival_objects/707458/children"
      SHELL
    end
    .example("python") do
    <<~PYTHON
      from asnake.client import ASnakeClient  # import the ArchivesSnake client
      
      client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
      # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
      
      client.authorize()  # authorizes the client
      
      get_children = client.get("/repositories/2/archival_objects/707458/children")
      # Replace 2 for your repository ID and 707458 with your archival object ID. Find these in the URI of your archival 
      # object on the bottom right of the Basic Information section in the staff interface
      
      print(get_children.json())
      # Output (list of dictionaries): [{'lock_version': 3, 'position': 0, 'publish': True, 'ref_id': '20029191',...}..]
    PYTHON
  end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "a list of archival object references"],
             [404, "Not found"]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])
    json_response(ao.children.map {|child|
                    ArchivalObject.to_jsonmodel(child)
                  })
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:id/previous')
    .description("Get the previous record of the same level in the tree for an Archival Object")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/2/archival_objects/707461/previous"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
        
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
        
        client.authorize()  # authorizes the client
        
        get_previous_ao = client.get("/repositories/2/archival_objects/707461/previous")
        # Replace 2 for your repository ID and 707461 with your archival object ID. Find these in the URI of your 
        # archival object on the bottom right of the Basic Information section in the staff interface
        
        print(get_children.json())
        # Output (dictionary): {'lock_version': 0, 'position': 0, 'publish': True, /
        # 'ref_id': '63a8c7d608936d85e85d08b9838d11c2', 'component_id': 'ref78192-11192', /
        # 'title': 'test_archival_object-FULL',...}
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:archival_object)"],
             [404, "No previous node"]) \
  do
    ao = ArchivalObject.get_or_die(params[:id]).previous_node

    json_response(ArchivalObject.to_jsonmodel(ao))
  end


  Endpoint.get('/repositories/:repo_id/archival_objects')
    .description("Get a list of Archival Objects for a Repository")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        # For all archival objects, use all_ids
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/2/archival_objects?all_ids=true"
        # For a set of archival objects, use id_set
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/2/archival_objects?id_set=707458&id_set=707460&id_set=707461"
        # For a page of archival objects, use page and page_size
        "http://localhost:8089/repositories/2/archival_objects?page=1&page_size=10"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
        
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
        
        client.authorize()  # authorizes the client
        
        # To get all archival objects for a repository, use all_ids parameter
        get_repo_aos_allids = client.get("repositories/6/archival_objects", params={"all_ids": True})
        # Replace 2 for your repository ID. Find this in the URI of your archival object on the bottom right of the 
        # Basic Information section in the staff interface

        # To get a set of archival objects for a repostiory, use id_set parameter
        get_repo_aos_set = client.get("repositories/2/archival_objects", params={"id_set": [707458, 707460, 707461]})
        # Replace 2 for your repository ID and the list of numbers for id_set with your archival object IDs. 
        # Find these in the URI of your archival object on the bottom right of the Basic Information section in the 
        # staff interface

        # To get a page of archival objects with a set page size, use "page" and "page_size" parameters
        get_repo_aos_pages = client.get("repositories/2/archival_objects", params={"page": 1, "page_size": 10})
        # Replace 2 for your repository ID. Find this in the URI of your archival object on the bottom right of the 
        # Basic Information section in the staff interface
        
        print(get_repo_aos_allids.json())
        # Output (list of IDs as integers): [687852, 687853, 687854, 687855, 687856, 687857, 687858,...]
        
        print(get_repo_aos_set.json())
        # Output (list of dictionaries): [{'lock_version': 0, 'position': 0, 'publish': True,...},...]

        print(get_repo_aos_pages.json())
        # Output (dictionary): {'first_page': 1, 'last_page': 26949, 'this_page': 1, 'total': 269488, //
        # 'results': [{'lock_version': 1, 'position': 0,...]...}
      PYTHON
    end
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:archival_object)]"]) \
  do
    handle_listing(ArchivalObject, params)
  end

  Endpoint.delete('/repositories/:repo_id/archival_objects/:id')
    .description("Delete an Archival Object")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" -X DELETE //
        "http://localhost:8089/repositories/2/archival_objects/707451"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
        
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
        
        client.authorize()  # authorizes the client
        
        delete_ao = client.delete("/repositories/2/archival_objects/707461")
        # Replace 2 for your repository ID and 707461 with your archival object ID. Find these in the URI of your 
        # archival object on the bottom right of the Basic Information section in the staff interface
        
        print(delete_ao.json())
        # Output (dictionary): {'status': 'Deleted', 'id': 707461}
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(ArchivalObject, params[:id])
  end

  Endpoint.post('/repositories/:repo_id/archival_objects/:id/publish')
    .description("Publish an Archival Object and all its sub-records and components")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" -X POST //
        "http://localhost:8089/repositories/2/archival_objects/707458/publish"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
        
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
        
        client.authorize()  # authorizes the client
        
        publish_ao = client.post("/repositories/2/archival_objects/707458/publish")
        # Replace 2 for your repository ID and 707458 with your archival object ID. Find these in the URI of your 
        # archival object on the bottom right of the Basic Information section in the staff interface
        
        print(publish_ao.json())
        # Output (dictionary): {'status': 'Updated', 'id': 707458, 'lock_version': 1, 'stale': None}
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .no_data(true)
    .returns([200, :updated],
             [400, :error]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])
    ao.publish!
    updated_response(ao)
  end

  Endpoint.post('/repositories/:repo_id/archival_objects/:id/unpublish')
    .description("Unpublish an Archival Object and all its sub-records and components")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" -X POST //
        "http://localhost:8089/repositories/2/archival_objects/707458/unpublish"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
        
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
        
        client.authorize()  # authorizes the client
        
        unpublish_ao = client.post("/repositories/2/archival_objects/707458/unpublish")
        # Replace 2 for your repository ID and 707458 with your archival object ID. Find these in the URI of your 
        # archival object on the bottom right of the Basic Information section in the staff interface
        
        print(unpublish_ao.json())
        # Output (dictionary): {'status': 'Updated', 'id': 707458, 'lock_version': 1, 'stale': None}
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .no_data(true)
    .returns([200, :updated],
             [400, :error]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])
    ao.unpublish!
    updated_response(ao)
  end

  Endpoint.get('/repositories/:repo_id/archival_objects/:id/models_in_graph')
    .description("Get a list of record types in the graph of an archival object")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/2/archival_objects/226994/models_in_graph"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
        
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
        
        client.authorize()  # authorizes the client
        
        get_ao_types = client.get("/repositories/2/archival_objects/226994/models_in_graph")
        # Replace 2 for your repository ID and 226994 with your archival object ID. Find these in the URI of your 
        # archival object on the bottom right of the Basic Information section in the staff interface
        
        print(get_ao_types.json())
        # Output (list): ['archival_object', 'extent', 'date', 'instance', 'external_id', 'sub_container']
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "OK"]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])

    graph = ao.object_graph

    record_types = graph.models.map {|m| m.my_jsonmodel(true) }.compact.map {|j| j.record_type}

    json_response(record_types)
  end
end
