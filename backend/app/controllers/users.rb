require_relative '../lib/auth_helpers'

class ArchivesSpaceService < Sinatra::Base

  include AuthHelpers


  Endpoint.post('/users')
    .description("Create a local user")
    .params(["password", String, "The user's password"],
            ["groups", [String], "Array of groups URIs to assign the user to", :optional => true],
            ["user", JSONModel(:user), "The user to create", :body => true])
    .preconditions(proc { current_user.can?(:manage_users) || "AnonymousUser" == current_user.class.name })
    .returns([200, :created],
             [400, :error]) \
  do
    params[:user].username = params[:user].username.downcase

    user = User.create_from_json(params[:user], :source => "local")
    DBAuth.set_password(params[:user].username, params[:password])

    groups = Array(params[:groups]).map {|uri| Group.any_repo[JSONModel(:group).id_for(uri)] || raise(NotFoundException.new("Group not found"))}
    user.add_to_groups(groups)

    created_response(user, params[:user])
  end


  Endpoint.get('/users')
    .description("Get a list of system users")
    .params(*Endpoint.pagination)
    .preconditions(proc { current_user.can?(:manage_users) })
    .returns([200, "[(:resource)]"]) \
  do
    handle_listing(User, params[:page], params[:page_size], params[:modified_since], {:exclude => {:id => User.unlisted_user_ids}})
  end


  Endpoint.get('/users/:id')
    .description("Get a user's details (including their current permissions)")
    .params(["id", Integer, "The username id to fetch"])
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
            ["user", JSONModel(:user), "The user to create", :body => true])
    .preconditions(proc { current_user.can?(:manage_users) })
    .returns([200, :updated],
             [400, :error]) \
  do
    params[:user].username = params[:user].username.downcase

    obj = User.get_or_die(params[:id])
    obj.update_from_json(params[:user])

    if params[:password]
      DBAuth.set_password(params[:user].username, params[:password])
    end

    updated_response(obj, params[:user])
  end


  Endpoint.post('/users/:username/login')
    .description("Log in")
    .params(["username", String, "Your username"],
            ["password", String, "Your password"],
            ["expiring", BooleanParam, "true if the created session should expire",
             :default => true])
    .returns([200, "Login accepted"],
             [403, "Login failed"]) \
  do
    username = params[:username].downcase

    user = AuthenticationManager.authenticate(username, params[:password])

    if user
      session = create_session_for(username, params[:expiring])
      json_user = User.to_jsonmodel(user)
      json_user.permissions = user.permissions
      json_response({:session => session.id, :user => json_user.to_hash})
    else
      json_response({:error => "Login failed"}, 403)
    end
  end

end
