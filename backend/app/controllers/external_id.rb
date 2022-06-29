class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/by-external-id')
    .description("List records by their external ID(s)")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089/users/admin/login" with your ASpace API URL
        # followed by "/users/{your_username}/login"
  
        set SESSION="session_id"
        # If using Git Bash, replace set with export
  
        curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/by-external-id?eid='3854'&type[]=resource"
        # Replace "http://localhost:8089" with your ASpace API URL, '3854' with the external id you are searching for, 
        # and type[]=resource with the type of record you want to search for (optional)
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
        
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
        
        client.authorize()  # authorizes the client
        
        find_eid = client.get("by-external-id", params={"eid": "3854", "type[]": "resource"})
        # Replace "3854" with the external id and "resource" with the type of record(s) you want to search - this is 
        # optional
        
        print(find_eid.json())
        # Output (dict): the JSON for the record returned. Other outputs include:
        # 303 – A redirect to the URI named by the external ID (if there’s only one)
        # 300 – A JSON-formatted list of URIs if there were multiple matches
        # 404 – No external ID matched
      PYTHON
    end
    .permissions([:view_all_records])
    .params(["eid", String, "An external ID to find"],
            ["type",
             [String],
             "The record type to search (useful if IDs may be shared between different types)",
             :optional => true])
    .returns([303, "A redirect to the URI named by the external ID (if there's only one)"],
             [300, "A JSON-formatted list of URIs if there were multiple matches"],
             [404, "No external ID matched"]) \
  do
    show_suppressed = !RequestContext.get(:enforce_suppression)

    query = Solr::Query.create_term_query("external_id", params[:eid]).
                        pagination(1, 10).
                        set_record_types(params[:type]).
                        show_suppressed(show_suppressed)

    results = Solr.search(query)

    if results['total_hits'] == 0
      [404, {}, "[]"]
    elsif results['total_hits'] == 1
      [303, {"Location" => results['results'][0]['uri']}, ""]
    else
      json_response(results['results'].map {|result| result['uri']}, 300)
    end
  end

end
