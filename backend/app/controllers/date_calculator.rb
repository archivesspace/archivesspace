class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/date_calculator')
    .description("Calculate the dates of an archival object tree")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089/users/admin/login" with your ASpace API URL
        # followed by "/users/{your_username}/login"

        set SESSION="session_id"
        # If using Git Bash, replace set with export

        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/date_calculator?record_uri=/repositories/4/archival_objects/336361"
        # Replace "http://localhost:8089" with your ASpace API URL and /repositories/4/archival_objects/336361 with the 
        # URI of the archival object
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client
        
        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
        
        client.authorize()  # authorizes the client
        
        calc_dates = client.get("date_calculator", params={"record_uri": "/repositories/4/archival_objects/336361"})
        # Replace "/repositories/4/archival_objects/336361" with the archival object URI
        
        print(calc_dates.json())
        # Output (dict): {'object':
        #                  {'uri': '/repositories/4/archival_objects/336361', 
        #                   'jsonmodel_type': 'archival_object', 
        #                   'title': 'Barrow, Middleton Pope. Papers', 
        #                   'id': 336361}, 
        #                 'resource': 
        #                  {'uri': '/repositories/4/resources/1820', 
        #                   'title': 'E. Merton Coulter manuscript collection II'}, 
        #                   'label': None, 
        #                   'min_begin_date': '1839-01-01', 
        #                   'min_begin': '1839', 
        #                   'max_end_date': '1903-12-31', 
        #                   'max_end': '1903'}
      PYTHON
    end
    .params(["record_uri", String, "The uri of the object"],
            ["label", String, "The date label to filter on", :optional => true])
    .permissions([])
    .returns([200, "Calculation results"]) \
    do
      parsed = JSONModel.parse_reference(params[:record_uri])

      RequestContext.open(:repo_id => JSONModel(:repository).id_for(parsed[:repository])) do
        raise AccessDeniedException.new unless current_user.can?(:view_repository)

        obj = Kernel.const_get(parsed[:type].to_s.camelize)[parsed[:id]]
        date_cal = DateCalculator.new(obj, params[:label])
        json_response(date_cal.to_hash)
      end
    end

end
