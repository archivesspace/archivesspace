class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/groups')
    .description("Create a group within a repository")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089" with your ASpace API URL followed by
        # "/users/{your_username}/login"

        set SESSION="session_id"
        # If using Windows, replace set with export

        curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id:/groups/" \\
        -d '{"group_code": "test-group_managers",
             "description": "Test group managers of the Manuscripts repository",
             "jsonmodel_type": "group"}'
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, and
        # the data found in -d with the metadata you want to create the new user group.

        # Output
        # {"status":"Created","id":24,"lock_version":0,"stale":null,"uri":"/repositories/2/groups/24","warnings":[]}
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        new_group = {
          "group_code": "test-group_managers",
          "description": "Test group managers of the Manuscripts repository",
          "jsonmodel_type": "group",
          "member_usernames": [
            "manager"
          ],
          "grants_permissions": [
            "cancel_job",
            "manage_enumeration_record"],
        }
        # This is a sample user group that exceeds the minimum requirements. The minimum requirements are:
        # jsonmodel_type, description, and group_code. grants_permissions is optional, these values can be looked up in
        # the ASpace database within the permissions table

        post_user_group = client.post("repositories/:repo_id:/groups", json=new_group)
        # Replace :repo_id: with the ArchivesSpace repository ID and new_group with the json data to create a new user
        # group

        print(post_user_group.json())
        # Output:
        # {'status': 'Created', 'id': 23, 'lock_version': 0, 'stale': None, 'uri': '/repositories/2/groups/23',
        # 'warnings': []}
      PYTHON
    end
    .params(["group", JSONModel(:group), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:manage_repository])
    .returns([200, :created],
             [400, :error],
             [409, :conflict]) \
  do
    handle_create(Group, params[:group])
  end


  Endpoint.post('/repositories/:repo_id/groups/:id')
    .description("Update a group")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089" with your ASpace API URL followed by
        # "/users/{your_username}/login"

        set SESSION="session_id"
        # If using Windows, replace set with export

        curl -H 'Content-Type: text/json' -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/:repo_id:/groups/:group_id:" \\
        -d '{"group_code": "test-group_managers",
             "lock_version": 4,
             "description": "Test group managers of the Manuscripts repository",
             "jsonmodel_type": "group",
             "member_usernames": [
                 "manager", "advance"]}'
        # Replace http://localhost:8089 with your ArchivesSpace API URL, :repo_id: with the repository ID number,
        # :group_id: with the group ID number you want to update, and the data found after -d with the data you want
        # updating the group. Be sure to include "lock_version" and the most recent number for it. You can find the
        # most recent lock_version by submitting a get request, like so: curl -H "X-ArchivesSpace-Session: $SESSION" \
        # "http://localhost:8089/repositories/:repo_id:/groups/:group_id:"

        # Output:
        # {"status":"Updated","id":23,"lock_version":5,"stale":null,"uri":"/repositories/2/groups/23","warnings":[]}
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        get_user_group = client.get("repositories/:repo_id:/groups/:group_id:").json()
        # Retrieve the data from the group you are trying to update. Replace :repo_id: with the repository ID number and
        # :group_id: with the group ID number you want to update

        get_user_group["member_usernames"].append("advance")
        # An example of how to modify a group record. For a list of all the fields you can update,
        # print(get_user_group). Here we append a new user 'advance' to the list of users associated with this group.

        update_user_group = get_user_group
        # Assign the newly updated get_user_group to update_user_group - to help make it clearer to see.

        update_status = client.post("repositories/:repo_id:/groups/:group_id:", json=update_user_group)
        # Replace :repo_id: with the repository ID number and :group_id: with the group ID number you want to update

        print(update_status.json())
        # Output:
        # {'status': 'Updated', 'id': 48, 'lock_version': 1, 'stale': None, 'uri': '/repositories/2/groups/48',
        # 'warnings': []}
      PYTHON
    end
    .params(["id", :id],
            ["group", JSONModel(:group), "The updated record", :body => true],
            ["repo_id", :repo_id],
            ["with_members",
             BooleanParam,
             "If 'true' (the default) replace the membership list with the list provided",
             :default => true])
    .permissions([:manage_repository])
    .returns([200, :updated],
             [400, :error],
             [409, :conflict]) \
  do
    handle_update(Group, params[:id], params[:group],
                  :with_members => params[:with_members])
  end


  Endpoint.get('/repositories/:repo_id/groups/:id')
    .description("Get a group by ID")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089" with your ASpace API URL followed by
        # "/users/{your_username}/login"

        set SESSION="session_id"
        # If using Windows, replace set with export

        curl -H "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id:/groups/:group_id:"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, and
        # :group_id: with the ID of the group you want to retrieve (usually found in the URL of the user group when
        # viewing in the staff interface)

        # Output
        # {"lock_version":203,"group_code":"repository-managers","description":"Managers of the Manuscripts..."}
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        get_user_group = client.get("repositories/:repo_id:/groups/:group_id:",
                                     params={"with_members": True})
        # Replace :repo_id: with the ArchivesSpace repository ID, :group_id: with the ArchivesSpace ID of the
        # user group, and change the "with_members" value to False if you do not want a list of members associated
        # with this group, otherwise list True - the default is True

        print(get_user_group.json())
        # Output: {"lock_version": 203, "group_code": "repository-managers", "description": "Managers of the
        # Manuscripts repository", etc...}
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["with_members",
             BooleanParam,
             "If 'true' (the default) return the list of members with the group",
             :default => true])
    .permissions([:manage_repository])
    .returns([200, "(:group)"],
             [404, "Not found"]) \
  do
    json = Group.to_jsonmodel(params[:id],
                              :with_members => params[:with_members])

    json_response(json)
  end


  Endpoint.delete('/repositories/:repo_id/groups/:id')
    .description("Delete a group by ID")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089" with your ASpace API URL followed by
        # "/users/{your_username}/login"

        set SESSION="session_id"
        # If using Windows, replace set with export

        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        -X DELETE "http://localhost:8089/repositories/:repo_id:/groups/:group_id:"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID, and
        # :group_id: with the ID of the group you want to delete (usually found in the URL of the user group when
        # viewing in the staff interface). Deleting is permanent so make sure to test this first!

        # Output: {"status":"Deleted","id":47}
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        delete_user_group = client.delete("repositories/:repo_id:/groups/:group_id:")
        # Replace :repo_id: with the ArchivesSpace repository ID and :group_id: with the ArchivesSpace ID of the
        # user group you want to delete. Deleting is permanent so make sure to test this first!

        print(delete_user_group.json())
        # Output: {'status': 'Deleted', 'id': 23}
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:manage_repository])
    .returns([200, "(:group)"],
             [404, "Not found"]) \
  do
    handle_delete(Group, params[:id])
  end


  Endpoint.get('/repositories/:repo_id/groups')
    .description("Get a list of groups for a repository")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        # Replace "admin" with your password and "http://localhost:8089" with your ASpace API URL followed by
        # "/users/{your_username}/login"

        set SESSION="session_id"
        # If using Windows, replace set with export

        curl -H
        "X-ArchivesSpace-Session: $SESSION" "http://localhost:8089/repositories/:repo_id:/groups"
        # Replace "http://localhost:8089" with your ASpace API URL, :repo_id: with the repository ID. Additionally,
        # you can add ?group_code=:group_id_number: as a parameter to specify a group, such as
        # http://localhost:8089/repositories/:repo_id:/groups?group_code=2

        # Output:
        # [{"lock_version":1,"group_code":"repository-advanced-data-entry","description":"Advanced Data Entry users
        # of the Manuscripts repository", etc.}]
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        get_user_group_info = client.get("repositories/:repo_id:/groups")
        # Replace :repo_id: with the ArchivesSpace repository ID. Add a "group_code" parameter to specify a group
        # code you want returned, such as client.get("repositories/:repo_id:/groups", params={"group_code": 2})

        print(get_user_group_info.json())
        # Output:
        # [{'lock_version': 1, 'group_code': 'repository-advanced-data-entry', 'description': 'Advanced Data Entry
        # users of the Manuscripts repository', etc.}]
      PYTHON
    end
    .params(["repo_id", :repo_id],
            ["group_code", String, "Get groups by group code",
             :optional => true])
    .permissions([:manage_repository])
    .returns([200, "[(:resource)]"]) \
  do
    handle_unlimited_listing(Group, params.has_key?(:group_code) ? {:group_code => params[:group_code]} : {})
  end
end
