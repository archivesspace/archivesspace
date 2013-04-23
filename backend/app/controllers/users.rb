require_relative '../lib/auth_helpers'

class ArchivesSpaceService < Sinatra::Base

  include AuthHelpers


  # FIXME: no restrictions on account creation just now because it's useful
  # for testing, but it feels like we shouldn't really let people create their
  # own accounts like this.
  Endpoint.post('/users')
    .description("Create a local user")
    .params(["password", String, "The user's password"],
            ["groups", [String], "Array of groups URIs to assign the user to", :optional => true],
            ["user", JSONModel(:user), "The user to create", :body => true])
    .permissions([])
    .returns([200, :created],
             [400, :error]) \
  do
    params[:user].username = Username.value(params[:user].username)

    user = User.create_from_json(params[:user], :source => "local")
    DBAuth.set_password(params[:user].username, params[:password])

    groups = Array(params[:groups]).map {|uri|
      group_ref = JSONModel.parse_reference(uri)
      repo_id = JSONModel.parse_reference(group_ref[:repository])[:id]

      RequestContext.open(:repo_id => repo_id) do
        if current_user.can?(:manage_repository)
          Group.get_or_die(group_ref[:id])
        else
          raise AccessDeniedException.new
        end
      end
    }

    user.add_to_groups(groups)

    created_response(user, params[:user])
  end


  Endpoint.get('/users')
    .description("Get a list of system users")
    .params(*Endpoint.pagination)
    .permissions([:manage_users])
    .returns([200, "[(:resource)]"]) \
  do
    handle_listing(User, params[:page], params[:page_size], params[:modified_since], {:exclude => {:id => User.unlisted_user_ids}})
  end


  Endpoint.get('/users/current-user')
    .description("Get the currently logged in user")
    .params()
    .permissions([])
    .returns([200, "(:user)"],
             [404, "Not logged in"]) \
  do
    if current_user.anonymous?
      raise NotFoundException.new
    else
      json = User.to_jsonmodel(current_user)
      json.permissions = current_user.permissions
      json_response(json)
    end
  end


  Endpoint.get('/users/complete')
    .description("Get a list of system users")
    .params(["query", String, "A prefix to search for"])
    .permissions([])
    .returns([200, "A list of usernames"]) \
  do
    usernames = AuthenticationManager.matching_usernames(params[:query])

    json_response(usernames)
  end


  Endpoint.get('/users/:id')
    .description("Get a user's details (including their current permissions)")
    .params(["id", Integer, "The username id to fetch"])
    .permissions([:manage_users])
    .returns([200, "(:user)"]) \
  do
    user = User[params[:id]]

    if user
      json = User.to_jsonmodel(user)
      json.permissions = user.permissions

      json_response(json)
    else
      raise NotFoundException.new("User wasn't found")
    end
  end


  Endpoint.post('/users/:id')
    .description("Update a user's account")
    .params(["id", Integer, "The username id to update"],
            ["password", String, "The user's password", :optional => true],
            ["groups", [String], "Array of groups URIs to assign the user to", :optional => true],
            ["repo_id", Integer, "The Repository groups to clear", :optional => true],
            ["user", JSONModel(:user), "The user to create", :body => true])
    .permissions([:manage_users])
    .returns([200, :updated],
             [400, :error]) \
  do
    params[:user].username = Username.value(params[:user].username)

    obj = User.get_or_die(params[:id])
    obj.update_from_json(params[:user])

    if params[:password]
      DBAuth.set_password(params[:user].username, params[:password])
    end

    if params[:groups] && params[:repo_id]
      groups = Array(params[:groups]).map {|uri|
        group_ref = JSONModel.parse_reference(uri)
        repo_id = JSONModel.parse_reference(group_ref[:repository])[:id]

        next if repo_id != params[:repo_id]

        RequestContext.open(:repo_id => repo_id) do
          if current_user.can?(:manage_repository)
            Group.get_or_die(group_ref[:id])
          else
            raise AccessDeniedException.new
          end
        end
      }

      obj.add_to_groups(groups, params[:repo_id])
    end

    updated_response(obj, params[:user])
  end


  Endpoint.post('/users/:username/login')
    .description("Log in")
    .params(["username", Username, "Your username"],
            ["password", String, "Your password"],
            ["expiring", BooleanParam, "true if the created session should expire",
             :default => true])
    .permissions([])
    .returns([200, "Login accepted"],
             [403, "Login failed"]) \
  do
    username = params[:username]

    user = AuthenticationManager.authenticate(username, params[:password])

    if user
      session = create_session_for(username, params[:expiring])
      json_user = User.to_jsonmodel(user)
      json_user.permissions = user.permissions
      json_response({:session => session.id, :user => json_user})
    else
      json_response({:error => "Login failed"}, 403)
    end
  end


  Endpoint.get('/repositories/:repo_id/users/:id')
  .description("Get a user's details including their groups for the current repository")
  .params(["id", Integer, "The username id to fetch"],
          ["repo_id", :repo_id])
  .permissions([:manage_repository])
  .returns([200, "(:user)"]) \
  do
    user = User[params[:id]]

    if user
      json = User.to_jsonmodel(user)
      json.groups = user.group_dataset.where(:repo_id => params[:repo_id]).map do |group|
        JSONModel(:group).uri_for(group.id, :repo_id => params[:repo_id])
      end

      json_response(json)
    else
      raise NotFoundException.new("User wasn't found")
    end
  end

end
