class ArchivesSpaceService < Sinatra::Base
  require_relative '../lib/merge_helpers'

  include MergeHelpers

  RESOLVE_LIST = ["subjects", "related_resources", "linked_agents", "revision_statements", "container_locations", "digital_object", "classifications", "related_agents", "resource", "parent", "creator", "linked_instances", "linked_records", "related_accessions", "linked_events", "linked_events::linked_records", "linked_events::linked_agents", "top_container", "container_profile", "location_profile", "owner_repo", "agent_places", "agent_occupations", "agent_functions", "agent_topics", "agent_resources", "places"]

  Endpoint.post('/merge_requests/subject')
    .description("Carry out a merge request against Subject records")
    .params(["merge_request",
             JSONModel(:merge_request), "A merge request",
             :body => true])
    .permissions([:merge_subject_record])
    .example('shell') do
      <<~SHELL
        curl -H 'Content-Type: application/json' \\
            -H "X-ArchivesSpace-Session: $SESSION" \\
            -d '{"uri": "merge_requests/subject", "merge_destination": {"ref": "/subjects/1"}, "merge_candidates": [{"ref": "/subjects/2"}]}' \\
            "http://localhost:8089/merge_requests/subject"
      SHELL
    end
    .example('python') do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
        
        client.authorize()  # authorizes the client
        
        updated_json = {'uri': 'merge_requests/subject',
                        'merge_destination': {'ref': subject_merge_into},
                        'merge_candidates': [{'ref': subject_uri_to_merge}]}
        # replace subject_merge_into for the URI of the subject you want to merge into and subject_uri_to_merge with the 
        # URI of the subject you want merged, i.e. subject_uri_to_merge >> subject_merge_into
        
        merge_response = client.post('merge_requests/subject', json=updated_json)
        # capture the response of the merge request
        
        print(merge_response.json())  # For error handling, you can print the response of the merge request
      PYTHON
    end
    .returns([200, :updated]) \
  do
    merge_destination, merge_candidates = parse_references(params[:merge_request])

    ensure_type(merge_destination, merge_candidates, 'subject')

    Subject.get_or_die(merge_destination[:id]).assimilate(merge_candidates.map {|v| Subject.get_or_die(v[:id])})

    merged_response( merge_destination, merge_candidates )
  end

  Endpoint.post('/merge_requests/container_profile')
    .description("Carry out a merge request against Container Profile records")
    .example('shell') do
      <<~SHELL
        curl -H 'Content-Type: application/json' \\
            -H "X-ArchivesSpace-Session: $SESSION" \\
            -d '{"uri": "merge_requests/container_profile", "merge_destination": {"ref": "/container_profiles/1" },"merge_candidates": [{"ref": "/container_profiles/2"}]}' \\
            "http://localhost:8089/merge_requests/container_profile"
      SHELL
    end
    .example('python') do
      <<~PYTHON
        from asnake.client import ASnakeClient
        client = ASnakeClient()
        client.authorize()
        client.post('/merge_requests/container_profile',
                json={
                    'uri': 'merge_requests/container_profile',
                    'merge_destination': {
                        'ref': '/container_profiles/1'
                      },
                    'merge_candidates': [
                        {
                            'ref': '/container_profiles/2'
                        }
                      ]
                    }
              )
      PYTHON
    end
    .params(["merge_request",
             JSONModel(:merge_request), "A merge request",
             :body => true])
    .permissions([:update_container_profile_record])
    .returns([200, :updated]) \
  do
    merge_destination, merge_candidates = parse_references(params[:merge_request])

    ensure_type(merge_destination, merge_candidates, 'container_profile')

    ContainerProfile.get_or_die(merge_destination[:id]).assimilate(merge_candidates.map {|v| ContainerProfile.get_or_die(v[:id])})

    merged_response( merge_destination, merge_candidates )
  end

  Endpoint.post('/merge_requests/top_container')
    .description("Carry out a merge request against Top Container records")
    .example('shell') do
      <<~SHELL
        curl -H 'Content-Type: application/json' \\
            -H "X-ArchivesSpace-Session: $SESSION" \\
            -d '{"uri": "merge_requests/top_container", "merge_destination": {"ref": "/repositories/2/top_containers/1" },"merge_candidates": [{"ref": "/repositories/2/top_containers/2"}]}' \\
            "http://localhost:8089/merge_requests/top_container?repo_id=2"
      SHELL
    end
    .example('python') do
      <<~PYTHON
        from asnake.client import ASnakeClient
        client = ASnakeClient()
        client.authorize()
        client.post('/merge_requests/top_container?repo_id=2',
                json={
                    'uri': 'merge_requests/top_container',
                    'merge_destination': {
                        'ref': '/repositories/2/top_containers/80'
                      },
                    'merge_candidates': [
                        {
                            'ref': '/repositories/2/top_containers/171'
                        }
                      ]
                    }
              )
      PYTHON
    end
    .params(["repo_id", :repo_id],
            ["merge_request",
             JSONModel(:merge_request), "A merge request",
             :body => true])
    .permissions([:manage_container_record])
    .returns([200, :updated]) \
  do
    merge_destination, merge_candidates = parse_references(params[:merge_request])

    check_repository(merge_destination, merge_candidates, params[:repo_id])
    ensure_type(merge_destination, merge_candidates, 'top_container')

    TopContainer.get_or_die(merge_destination[:id]).assimilate(merge_candidates.map {|v| TopContainer.get_or_die(v[:id])})

    merged_response( merge_destination, merge_candidates )
  end


  Endpoint.post('/merge_requests/agent')
    .description("Carry out a merge request against Agent records")
    .params(["merge_request",
             JSONModel(:merge_request), "A merge request",
             :body => true])
    .permissions([:merge_agent_record])
    .returns([200, :updated]) \
  do
    merge_destination, merge_candidates = parse_references(params[:merge_request])

    if (merge_candidates.map {|r| r[:type]} + [merge_destination[:type]]).any? {|type| !AgentManager.known_agent_type?(type)}
      raise BadParamsException.new(:merge_request => ["Agent merge request can only merge agent records"])
    end

    agent_model = AgentManager.model_for(merge_destination[:type])
    agent_model.get_or_die(merge_destination[:id]).assimilate(merge_candidates.map {|v|
                                                     AgentManager.model_for(v[:type]).get_or_die(v[:id])
                                                   })

    merged_response( merge_destination, merge_candidates )
  end

  # Shell example for /merge_requests/agent_detail below illustrates an agent merge where:
  # - Only the primary name field from the FIRST (position = 0) merge_candidate agent record replaces the primary name field in the merge_destination. After the merge, the rest of the merge_candidate name record is discarded
  # - The entire FIRST (position = 0) agent_record_identifer record from the merge_candidate is added to the set of agent_record_identifier records in the merge_destination at the end (position = n + 1)
  # - The entire SECOND (position = 1) agent_conventions_declaration from the merge_candidate replaces the FIRST (because it is at index = 0 in agent_conventions_declaration array in json below)agent_conventions_declaration record in the merge_destination
  # - The entire FIRST (position = 0) agent_conventions_declaration from the merge_candidate replaces the SECOND (because it is at index = 1 in agent_conventions_declaration array in json below)agent_conventions_declaration record in the merge_destination
  Endpoint.post('/merge_requests/agent_detail')
  .description("Carry out a detailed merge request against Agent records")
  .example('shell') do
      <<~SHELL
        curl -H 'Content-Type: application/json' \\
            -H "X-ArchivesSpace-Session: $SESSION" \\
            -d '{"dry_run":true, \\
                 "merge_request_detail":{ \\
                   "jsonmodel_type":"merge_request_detail", \\
                   "merge_candidates":[{"ref":"/agents/people/3"}], \\
                   "merge_destination":{"ref":"/agents/people/4"}, \\
                   "selections":{
                     "names":[{"primary_name":"REPLACE", "position":"0"}], \\
                     "agent_record_identifiers":[{"append":"APPEND", "position":"0"}], \\
                     "agent_conventions_declarations":[
                       {"append":"REPLACE", "position":"1"}, \\
                       {"append":"REPLACE", "position":"0"} \\
                      ],
                   } \\
                } \\
              } \\
            "http://localhost:8089/merge_requests/agent_detail"
      SHELL
    end
  .params(["dry_run", BooleanParam, "If true, don't process the merge, just display the merged record", :optional => true],
          ["merge_request_detail",
             JSONModel(:merge_request_detail), "A detailed merge request",
             :body => true])
  .permissions([:merge_agent_record])
  .returns([200, :updated]) \
  do
    merge_destination, merge_candidates = parse_references(params[:merge_request_detail])
    selections = parse_selections(params[:merge_request_detail].selections)

    if (merge_candidates.map {|r| r[:type]} + [merge_destination[:type]]).any? {|type| !AgentManager.known_agent_type?(type)}
      raise BadParamsException.new(:merge_request_detail => ["Agent merge request can only merge agent records"])
    end
    agent_model = AgentManager.model_for(merge_destination[:type])
    merge_destination_obj = agent_model.get_or_die(merge_destination[:id])
    merge_candidate_obj = agent_model.get_or_die(merge_candidates[0][:id])
    merge_destination_json = agent_model.to_jsonmodel(merge_destination_obj)
    merge_candidate_json = agent_model.to_jsonmodel(merge_candidate_obj)
    new_merge_destination = merge_details(merge_destination_json, merge_candidate_json, selections, params)
    result = resolve_references(new_merge_destination, RESOLVE_LIST)

    # if this is not a dry run, commit the merge.
    # otherwise, we'll send the response without saving any results.
    unless params[:dry_run]
      merge_destination_obj.assimilate((merge_candidates.map {|v|
                                       AgentManager.model_for(v[:type]).get_or_die(v[:id])
                                     }))

      #update lock version which may have happened during call to #assimilate
      merge_destination_json_updated = agent_model.to_jsonmodel(merge_destination_obj)
      new_merge_destination['lock_version'] = merge_destination_json_updated['lock_version']

      if selections != {}
        begin
          merge_destination_obj.update_from_json(new_merge_destination)
        rescue => e
          STDERR.puts "EXCEPTION!"
          STDERR.puts e.message
          STDERR.puts e.backtrace
        end
      end
    end

    merged_response(merge_destination, merge_candidates, selections, result)
  end


  Endpoint.post('/merge_requests/resource')
    .description("Carry out a merge request against Resource records")
    .params(["repo_id", :repo_id],
            ["merge_request",
             JSONModel(:merge_request), "A merge request",
             :body => true])
    .permissions([:merge_archival_record])
    .returns([200, :updated]) \
  do
    merge_destination, merge_candidates = parse_references(params[:merge_request])

    check_repository(merge_destination, merge_candidates, params[:repo_id])
    ensure_type(merge_destination, merge_candidates, 'resource')

    Resource.get_or_die(merge_destination[:id]).assimilate(merge_candidates.map {|v| Resource.get_or_die(v[:id])})

    merged_response( merge_destination, merge_candidates )
  end


  Endpoint.post('/merge_requests/digital_object')
    .description("Carry out a merge request against Digital_Object records")
    .params(["repo_id", :repo_id],
            ["merge_request",
             JSONModel(:merge_request), "A merge request",
             :body => true])
    .permissions([:merge_archival_record])
    .returns([200, :updated]) \
  do
    merge_destination, merge_candidates = parse_references(params[:merge_request])

    check_repository(merge_destination, merge_candidates, params[:repo_id])
    ensure_type(merge_destination, merge_candidates, 'digital_object')

    DigitalObject.get_or_die(merge_destination[:id]).assimilate(merge_candidates.map {|v| DigitalObject.get_or_die(v[:id])})

    merged_response( merge_destination, merge_candidates )
  end
end
