class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/accessions/:id/suppressed')
  .description("Suppress this record")
  .example("shell") do
    <<~SHELL
      curl -s -F password="password" "http://localhost:8089/users/:your_username:/login"
      # Replace "password" with your password, "http://localhost:8089 with your ASpace API URL, and :your_username: with
      # your ArchivesSpace username
      
      set SESSION="session_id"
      # If using Git Bash, replace set with export

      curl -X POST -H "X-ArchivesSpace-Session: $SESSION" //
      "http://localhost:8089/repositories/:repo_id:/accessions/:accession_id:/suppressed?suppressed=true"
      # Replace http://localhost:8089 with your ArchivesSpace API URL, :repo_id: with the ArchivesSpace repository ID,
      # :accession_id: with the ArchivesSpace ID of the accession, and change the "suppressed" value to true to suppress
      # the accession or false to unsuppress the accession
      
      # Output: {"status":"Suppressed","id":3828,"suppressed_state":true}
    SHELL
  end
  .example("python") do
    <<~PYTHON
      from asnake.client import ASnakeClient  # import the ArchivesSnake client

      client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
      # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
      
      client.authorize()  # authorizes the client

      suppress_accession = client.post("repositories/:repo_id:/accessions/:accession_id:/suppressed",
                                       params={"suppressed": True})
      # Replace :repo_id: with the ArchivesSpace repository ID, :accession_id: with the ArchivesSpace ID of the 
      # accession, and change the "suppressed" value to True to suppress the accession or False to unsuppress the 
      # accession
      
      print(suppress_accession.json())
      # Output: {'status': 'Suppressed', 'id': 3828, 'suppressed_state': True}
    PYTHON
  end
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .no_data(true)
  .returns([200, :suppressed]) \
  do
    sup_state = Accession.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end


  Endpoint.post('/repositories/:repo_id/resources/:id/suppressed')
  .description("Suppress this record")
  .example("shell") do
    <<~SHELL
      curl -s -F password="password" "http://localhost:8089/users/:your_username:/login"
      # Replace "password" with your password, "http://localhost:8089 with your ASpace API URL, and :your_username: with
      # your ArchivesSpace username
      
      set SESSION="session_id"
      # If using Git Bash, replace set with export

      curl -X POST -H "X-ArchivesSpace-Session: $SESSION" //
      "http://localhost:8089/repositories/:repo_id:/resources/:resource_id:/suppressed?suppressed=true"
      # Replace http://localhost:8089 with your ArchivesSpace API URL, :repo_id: with the ArchivesSpace repository ID,
      # :resource_id: with the ArchivesSpace ID of the resource, and change the "suppressed" value to true to suppress 
      # the resource or false to unsuppress the resource
      
      # Output: {"status":"Suppressed","id":5812,"suppressed_state":true}
    SHELL
  end
  .example("python") do
    <<~PYTHON
      from asnake.client import ASnakeClient  # import the ArchivesSnake client

      client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
      # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
      
      client.authorize()  # authorizes the client

      suppress_resource = client.post("/repositories/:repo_id:/resources/:resource_id:/suppressed",
                                      params={"suppressed": False})
      # Replace :repo_id: with the ArchivesSpace repository ID, :resource_id: with the ArchivesSpace ID of the resource,
      # and change the "suppressed" value to True to suppress the resource or False to unsuppress the resource
      
      print(suppress_resource.json())
      # Output: {'status': 'Suppressed', 'id': 5812, 'suppressed_state': True}
    PYTHON
  end
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .no_data(true)
  .returns([200, :suppressed]) \
  do
    sup_state = Resource.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id/suppressed')
  .description("Suppress this record")
  .example("shell") do
    <<~SHELL
      curl -s -F password="password" "http://localhost:8089/users/:your_username:/login"
      # Replace "password" with your password, "http://localhost:8089 with your ASpace API URL, and :your_username: with
      # your ArchivesSpace username
      
      set SESSION="session_id"
      # If using Git Bash, replace set with export

      curl -X POST -H "X-ArchivesSpace-Session: $SESSION" //
      "http://localhost:8089/repositories/:repo_id:/archival_objects/:archobj_id:/suppressed?suppressed=true"
      # Replace http://localhost:8089 with your ArchivesSpace API URL, :repo_id: with the ArchivesSpace repository ID,
      # :archobj_id: with the ArchivesSpace ID of the archival object, and change the "suppressed" value to true to 
      # suppress the archival object or false to unsuppress the archival object
      
      # Output: {"status":"Suppressed","id":717782,"suppressed_state":true}
    SHELL
  end
  .example("python") do
    <<~PYTHON
      from asnake.client import ASnakeClient  # import the ArchivesSnake client

      client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
      # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
      
      client.authorize()  # authorizes the client

      suppress_archobj = client.post("/repositories/:repo_id:/archival_objects/:archobj_id:/suppressed",
                                     params={"suppressed": True})
      # Replace :repo_id: with the ArchivesSpace repository ID, :archobj_id: with the ArchivesSpace ID of the archival 
      # object, and change the "suppressed" value to True to suppress the archival object or False to unsuppress the 
      # archival object
      
      print(suppress_archobj.json())
      # Output: {'status': 'Suppressed', 'id': 717782, 'suppressed_state': True}
    PYTHON
  end
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .no_data(true)
  .returns([200, :suppressed]) \
  do
    sup_state = ArchivalObject.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id/suppressed')
  .description("Suppress this record")
  .example("shell") do
    <<~SHELL
      curl -s -F password="password" "http://localhost:8089/users/:your_username:/login"
      # Replace "password" with your password, "http://localhost:8089 with your ASpace API URL, and :your_username: with
      # your ArchivesSpace username
      
      set SESSION="session_id"
      # If using Git Bash, replace set with export

      curl -X POST -H "X-ArchivesSpace-Session: $SESSION" //
      "http://localhost:8089/repositories/:repo_id:/digital_objects/:digobj_id:/suppressed?suppressed=false"
      # Replace http://localhost:8089 with your ArchivesSpace API URL, :repo_id: with the ArchivesSpace repository ID,
      # :digobj_id: with the ArchivesSpace ID of the digital object, and change the "suppressed" value to true to 
      # suppress the digital object or false to unsuppress the digital object
      
      # Output: {"status":"Suppressed","id":14098,"suppressed_state":true}
    SHELL
  end
  .example("python") do
    <<~PYTHON
      from asnake.client import ASnakeClient  # import the ArchivesSnake client

      client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
      # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
      
      client.authorize()  # authorizes the client

      suppress_digobj = client.post("/repositories/:repo_id:/digital_objects/:digobj_id:/suppressed",
                                    params={"suppressed": True})
      # Replace :repo_id: with the ArchivesSpace repository ID, :digobj_id: with the ArchivesSpace ID of the digital 
      # object, and change the "suppressed" value to True to suppress the digital object or False to unsuppress the 
      # digital object
      
      print(suppress_digobj.json())
      # Output: {'status': 'Suppressed', 'id': 14098, 'suppressed_state': True}
    PYTHON
  end
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .no_data(true)
  .returns([200, :suppressed]) \
  do
    sup_state = DigitalObject.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end


  Endpoint.post('/repositories/:repo_id/digital_object_components/:id/suppressed')
  .description("Suppress this record")
          .example("shell") do
    <<~SHELL
      curl -s -F password="password" "http://localhost:8089/users/:your_username:/login"
      # Replace "password" with your password, "http://localhost:8089 with your ASpace API URL, and :your_username: with
      # your ArchivesSpace username
      
      set SESSION="session_id"
      # If using Git Bash, replace set with export

      curl -X POST -H "X-ArchivesSpace-Session: $SESSION" //
      "http://localhost:8089/repositories/:repo_id:/digital_object_components/:digobjcomp_id:/suppressed?suppressed=true"
      # Replace http://localhost:8089 with your ArchivesSpace API URL, :repo_id: with the ArchivesSpace repository ID,
      # :digobjcomp_id: with the ArchivesSpace ID of the digital object component, and change the "suppressed" value to
      # True to suppress the digital object component or False to unsuppress the digital object component
      
      # Output: {"status":"Suppressed","id":3,"suppressed_state":true}
    SHELL
  end
    .example("python") do
    <<~PYTHON
      from asnake.client import ASnakeClient  # import the ArchivesSnake client

      client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
      # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
      
      client.authorize()  # authorizes the client

      suppress_digobjcomp = client.post("/repositories/:repo_id:/digital_object_components/:digobjcomp_id:/suppressed",
                                        params={"suppressed": True})
      # Replace :repo_id: with the ArchivesSpace repository ID, :digobjcomp_id: with the ArchivesSpace ID of the digital
      # object component, and change the "suppressed" value to True to suppress the digital object component or False to
      # unsuppress the digital object component
      
      print(suppress_digobjcomp.json())
      # Output: {'status': 'Suppressed', 'id': 3, 'suppressed_state': True}
    PYTHON
  end
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .no_data(true)
  .returns([200, :suppressed]) \
  do
    sup_state = DigitalObjectComponent.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end

end
