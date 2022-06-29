class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/version')
    .description("Get the ArchivesSpace application version")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089/users/admin/login" with your ASpace API URL
        # followed by "/users/{your_username}/login"
  
        set SESSION="session_id"
        # If using Git Bash, replace set with export
  
        curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/version"
        # Replace "http://localhost:8089" with your ASpace API URL
      SHELL
    end
    .example("python") do
    <<~PYTHON
      from asnake.client import ASnakeClient  # import the ArchivesSnake client
      
      client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
      # Replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password
      
      client.authorize()  # authorizes the client
      
      aspace_version = client.get("/version")
      # Retrieves the ArchivesSpace version
      
      print(aspace_version.content.decode())
      # Output (str): ArchivesSpace (v3.1.1)
      # Use .content.decode() to print the response since .json() returns a JSON decoding error
    PYTHON
  end
    .params()
    .permissions([])
    .returns([200, "ArchivesSpace (version)"]) \
  do
    "ArchivesSpace (#{ASConstants.VERSION})"
  end

end
