class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/find_by_id/resources')
    .description("Find Resources by their identifiers")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089/users/admin/login" with your ASpace API URL
        # followed by "/users/{your_username}/login"
  
        set SESSION="session_id"
        # If using Git Bash, replace set with export
  
        # Finding resources with one identifier field
  
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        -G http://localhost:8089/repositories/:repo_id:/find_by_id/resources //
        --data-urlencode 'identifier[]=["your_id_here"]' --data-urlencode 'resolve[]=resources'
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "your_id_here" with the ID you are searching for, and only add --data-urlencode 'resolve[]=resources' if you 
        # want the JSON for the returned record - otherwise, it will return the record URI only
  
        # Output: {"resources":[{"ref":"/repositories/2/resources/476","_resolved":{"lock_version":0,"title":...}
  
        # Finding resources with multiple identifier fields
  
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        -G http://localhost:8089/repositories/:repo_id:/find_by_id/resources //
        --data-urlencode 'identifier[]=["test","1234","abcd","5678"]' --data-urlencode 'resolve[]=resources'
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "test", "1234", "abcd", and "5678" with the ID you are searching for, and only add 
        # --data-urlencode 'resolve[]=resources' if you want the JSON for the returned record - otherwise, it will return 
        # the record URI only
  
        # Output: {"resources":[{"ref":"/repositories/2/resources/476","_resolved":{"lock_version":0,"title":...}
  
        # Finding multiple resources using identifier fields
        
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        -G http://http://localhost:8089/repositories/:repo_id:/find_by_id/resources //
        --data-urlencode 'identifier[]=["test","1234","abcd","5678"]' --data-urlencode 'identifier[]=["your_id_here"]' //
        --data-urlencode 'resolve[]=resources'
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "test", "1234", "abcd", "5678", and "your_id_here" with the ID you are searching for, and only add 
        # --data-urlencode 'resolve[]=resources' if you want the JSON for the returned record - otherwise, it will return 
        # the record URI only
  
        # Output: {"resources":[{"ref":"/repositories/2/resources/455"},{"ref":"/repositories/2/resources/456"}]}

        # Finding resources with ARKs
        
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/:repo_id:/find_by_id/resources?ark[]=ark%3A%2F####%2F######;resolve[]=resources"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # ark%3A%2F####%2F###### with the ARK you are searching for - NOTE, make sure to encode any characters like 
        # : into %3A and / into %2F - and only add resolve[]=resources if you want the JSON for the returned record - 
        # otherwise, it will return the record URI only
  
        # Output: {"resources":[{"ref":"/repositories/2/resources/455"},{"ref":"/repositories/2/resources/456"}]}

        # If you are having trouble resolving the URL, try using the --data-urlencode parameter, like so:
        # curl -H "X-ArchivesSpace-Session: $SESSION" -G //
        # http://localhost:8089/repositories/2/find_by_id/resources --data-urlencode 'ark[]=ark%3A%2F####%2F######'
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
  
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace "http://localhost:8089" with your ArchivesSpace API URL and "admin" for your username and password
  
        client.authorize()  # authorizes the client
  
        # Finding resources with one identifier field
  
        find_single_resid = client.get('repositories/:repo_id:/find_by_id/resources', params={'identifier[]': 
                                                                                                  ['["your_id_here"]'], 
                                                                                              'resolve[]': 'resources'})
        # Replace :repo_id: with the repository ID the resource is in, "your_id_here" with the ID you are searching for,
        # and only add 'resolve[]': 'resources' if you want the JSON for the returned record - otherwise, it will return 
        # the record URI only
  
        print(find_single_resid.json())
        # Output (dict): {'resources': [{'ref': '/repositories/2/resources/407', '_resolved':  {'lock_version': 0,...}
  
        # Finding resources with multiple identifier fields
  
        find_multi_resid = client.get('repositories/:repo_id:/find_by_id/resources', params={'identifier[]': 
                                                                                                 ['["test", "1234", "abcd", "5678"]'], 
                                                                                             'resolve[]': 'resources'})
        # Replace :repo_id: with the repository ID the resource is in, "test", "1234", "abcd", and "5678" with the ID 
        # you are searching for, and only add 'resolve[]': 'resources' if you want the JSON for the returned record - 
        # otherwise, it will return the record URI only
  
        print(find_multi_resid.json())
        # Output (dict): {'resources': [{'ref': '/repositories/2/resources/407', '_resolved':  {'lock_version': 0,...}

        # Finding resources with ARKs

        find_res_ark = client.get("repositories/:repo_id:/find_by_id/resources", 
                                  params={"ark[]": "ark:/######/##/##",
                                  "resolve[]": "resources"})
        # Replace :repo_id: with the repository ID, "ark:/######/##/##" with the ark ID you are searching for, and only 
        # add "resolve[]": "resources" if you want the JSON for the returned record - otherwise, it will return 
        # the record URI only
  
        print(find_res_ark.json())
        # Output (dict): {'resources': [{'ref': '/repositories/2/resources/407', '_resolved':  {'lock_version': 0,...}
      PYTHON
    end
    .params(["repo_id", :repo_id],
            ["identifier", [String], "A 4-part identifier expressed as a JSON array (of up to 4 strings) comprised of the id_0 to id_3 fields (though empty fields will be handled if not provided)", :optional => true],
            ["ark", [String], "An ARK attached to a resource record (param may be repeated)", :optional => true],
            ["resolve", :resolve, "The type of record you are resolving, returns the full JSON for linked record. Example: 'resolve[]': 'resources'", :optional => true])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(Resource, params)
    json_response(resolve_references({'resources' => refs}, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/find_by_id/archival_objects')
    .description("Find Archival Objects by ref_id or component_id")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089/users/admin/login" with your ASpace API URL
        # followed by "/users/{your_username}/login"
  
        set SESSION="session_id"
        # If using Git Bash, replace set with export
  
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/:repo_id:/find_by_id/archival_objects?component_id[]=hello_im_a_component_id;resolve[]=archival_objects"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "hello_im_a_component_id" with the component ID you are searching for, and only add 
        # "resolve[]=archival_objects" if you want the JSON for the returned record - otherwise, it will return the 
        # record URI only
  
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/:repo_id:/find_by_id/archival_objects?ref_id[]=hello_im_a_ref_id;resolve[]=archival_objects"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "hello_im_a_ref_id" with the ref ID you are searching for, and only add 
        # "resolve[]=archival_objects" if you want the JSON for the returned record - otherwise, it will return the 
        # record URI only

        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/:repo_id:/find_by_id/archival_objects?ark[]=ark%3A%2F####%2F######;resolve[]=archival_objects"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "ark%3A%2F####%2F######" with the ark you are searching for - NOTE, make sure to encode any characters like 
        # : into %3A and / into %2F - and only add "resolve[]=archival_objects" if you want the JSON for the returned 
        # record - otherwise, it will return the record URI only

        # If you are having trouble resolving the URL, try using the --data-urlencode parameter, like so:
        # curl -H "X-ArchivesSpace-Session: $SESSION" -G //
        # http://localhost:8089/repositories/2/find_by_id/archival_objects --data-urlencode 'ark[]=ark%3A%2F####%2F######'
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
  
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace "http://localhost:8089" with your ArchivesSpace API URL and "admin" for your username and password
  
        client.authorize()  # authorizes the client
  
        find_ao_compid = client.get("repositories/:repo_id:/find_by_id/archival_objects", 
                                    params={"component_id[]": "hello_im_a_component_id",
                                    "resolve[]": "archival_objects"})
        # Replace :repo_id: with the repository ID, "hello_im_a_component_id" with the component ID you are searching for, and
        # only add "resolve[]": "archival_objects" if you want the JSON for the returned record - otherwise, it will 
        # return the record URI only
  
        print(find_ao_compid.json())
        # Output (dict): {'archival_objects': [{'ref': '/repositories/2/archival_objects/708425', '_resolved':...}]}
  
        find_ao_refid = client.get("repositories/:repo_id:/find_by_id/archival_objects", 
                                   params={"ref_id[]": "hello_im_a_ref_id",
                                   "resolve[]": "archival_objects"})
        # Replace :repo_id: with the repository ID, "hello_im_a_ref_id" with the ref ID you are searching for, and only add 
        # "resolve[]": "archival_objects" if you want the JSON for the returned record - otherwise, it will return the 
        # record URI only
  
        print(find_ao_refid.json())
        # Output (dict): {'archival_objects': [{'ref': '/repositories/2/archival_objects/708425', '_resolved':...}]}

        find_ao_ark = client.get("repositories/:repo_id:/find_by_id/archival_objects", 
                                 params={"ark[]": "ark:/######/##/##",
                                 "resolve[]": "archival_objects"})
        # Replace :repo_id: with the repository ID, "ark:/######/##/##" with the ark ID you are searching for, and only 
        # add "resolve[]": "archival_objects" if you want the JSON for the returned record - otherwise, it will return 
        # the record URI only
  
        print(find_ao_ark.json())
        # Output (dict): {'archival_objects': [{'ref': '/repositories/2/archival_objects/708425', '_resolved':...}]}
      PYTHON
    end
    .params(["repo_id", :repo_id],
            ["ref_id", [String], "An archival object's Ref ID (param may be repeated)", :optional => true],
            ["component_id", [String], "An archival object's component ID (param may be repeated)", :optional => true],
            ["ark", [String], "An ARK attached to an archival object record (param may be repeated)", :optional => true],
            ["resolve", :resolve, "The type of record you are resolving, returns the full JSON for linked record. Example: 'resolve[]': 'archival_object'", :optional => true])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(ArchivalObject, params)
    json_response(resolve_references({'archival_objects' => refs}, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/find_by_id/digital_object_components')
    .description("Find Digital Object Components by component_id")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089/users/admin/login" with your ASpace API URL
        # followed by "/users/{your_username}/login"
  
        set SESSION="session_id"
        # If using Git Bash, replace set with export
  
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/:repo_id:/find_by_id/digital_object_components?component_id[]=im_a_do_component_id;resolve[]=digital_object_components"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "im_a_do_component_id" with the component ID you are searching for, and only add 
        # "resolve[]=digital_object_components" if you want the JSON for the returned record - otherwise, it will return
        # the record URI only
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
  
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace "http://localhost:8089" with your ArchivesSpace API URL and "admin" for your username and password
  
        client.authorize()  # authorizes the client
  
        find_do_comp = client.get("repositories/:repo_id:/find_by_id/digital_object_components", 
                                  params={"component_id[]": "im_a_do_component_id",
                                  "resolve[]": "digital_object_components"})
        # Replace :repo_id: with the repository ID, "im_a_do_component_id" with the component ID you are searching for, and
        # only add "resolve[]": "digital_object_components" if you want the JSON for the returned record - otherwise, it
        # will return the record URI only
  
        print(find_do_comp.json())
        # Output (dict): {'digital_object_components': [{'ref': '/repositories/2/digital_object_components/1', '_resolved':...}]}
      PYTHON
    end
    .params(["repo_id", :repo_id],
            ["component_id", [String], "A digital object component's component ID (param may be repeated)", :optional => true],
            ["resolve", :resolve, "The type of record you are resolving, returns the full JSON for linked record. Example: 'resolve[]': 'digital_object_components'", :optional => true])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(DigitalObjectComponent, params)
    json_response(resolve_references({'digital_object_components' => refs}, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/find_by_id/digital_objects')
    .description("Find Digital Objects by digital_object_id")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089/users/admin/login" with your ASpace API URL
        # followed by "/users/{your_username}/login"
  
        set SESSION="session_id"
        # If using Git Bash, replace set with export
  
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/:repo_id:/find_by_id/digital_objects?digital_object_id[]=hello_im_a_digobj_id;resolve[]=digital_objects"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "hello_im_a_digobj_id" with the digital object ID you are searching for, and only add 
        # "resolve[]=digital_objects" if you want the JSON for the returned record - otherwise, it will return the 
        # record URI only
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
  
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace "http://localhost:8089" with your ArchivesSpace API URL and "admin" for your username and password
  
        client.authorize()  # authorizes the client
  
        find_do = client.get("repositories/:repo_id:/find_by_id/digital_objects", 
                             params={"digital_object_id[]": "hello_im_a_digobj_id", 
                                     "resolve[]": "digital_objects"})
        # Replace :repo_id: with the repository ID, "im_a_digobj_id" with the digital object ID you are searching for, and
        # only add "resolve[]=digital_objects" if you want the JSON for the returned record - otherwise, it will return 
        # the record URI only
  
        print(find_do.json())
        # Output (dict): {'digital_objects': [{'ref': '/repositories/2/digital_objects/1', '_resolved':...}]}
      PYTHON
    end
    .params(["repo_id", :repo_id],
            ["digital_object_id", [String], "A digital object's digital object ID (param may be repeated)", :optional => true],
            ["resolve", :resolve, "The type of record you are resolving, returns the full JSON for linked record. Example: 'resolve[]': 'digital_objects'", :optional => true])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(DigitalObject, params)
    json_response(resolve_references({'digital_objects' => refs}, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/find_by_id/top_containers')
    .description("Find Top Containers by their indicators or barcodes")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089/users/admin/login" with your ASpace API URL
        # followed by "/users/{your_username}/login"
    
        set SESSION="session_id"
        # If using Git Bash, replace set with export
    
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/:repo_id:/find_by_id/top_containers?indicator[]=123;resolve[]=top_containers"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "123" with the indicator you are searching for, and only add 
        # "resolve[]=top_containers" if you want the JSON for the returned record - otherwise, it will return the 
        # record URI only
    
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/:repo_id:/find_by_id/top_containers?barcode[]=123456789;resolve[]=top_containers"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, 
        # "123456789" with the barcode you are searching for, and only add 
        # "resolve[]=top_containers" if you want the JSON for the returned record - otherwise, it will return the 
        # record URI only
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
  
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace "http://localhost:8089" with your ArchivesSpace API URL and "admin" for your username and password
  
        client.authorize()  # authorizes the client
  
        find_tc = client.get("repositories/:repo_id:/find_by_id/top_containers", 
                             params={"indicator[]": "123", 
                                     "resolve[]": "top_containers"})
        # Replace :repo_id: with the repository ID, "123" with the indicator you are searching for, and
        # only add "resolve[]=digital_objects" if you want the JSON for the returned record - otherwise, it will return 
        # the record URI only
  
        print(find_tc.json())
        # Output (dict): {'top_containers': [{'ref': '/repositories/2/top_containers/9876', '_resolved':...}]}
  
        find_tc = client.get("repositories/:repo_id:/find_by_id/top_containers", 
                             params={"barcode[]": "123456789", 
                                     "resolve[]": "top_containers"})
        # Replace :repo_id: with the repository ID, "123456789" with the barcode you are searching for, and
        # only add "resolve[]=digital_objects" if you want the JSON for the returned record - otherwise, it will return 
        # the record URI only
  
        print(find_tc.json())
        # Output (dict): {'top_containers': [{'ref': '/repositories/2/top_containers/9876', '_resolved':...}]}
      PYTHON
    end
    .params(["repo_id", :repo_id],
            ["indicator", [String], "A top container's indicator (param may be repeated)", :optional => true],
            ["barcode", [String], "A top container's barcode (param may be repeated)", :optional => true],
            ["resolve", :resolve, "The type of record you are resolving, returns the full JSON for linked record. Example: 'resolve[]': 'top_containers'", :optional => true])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(TopContainer, params)
    json_response(resolve_references({'top_containers' => refs}, params[:resolve]))
  end

end
