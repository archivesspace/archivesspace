require_relative '../lib/auth_helpers'

class ArchivesSpaceService < Sinatra::Base

  include AuthHelpers


  Endpoint.post('/users')
    .description("Create a local user")
    .params(["password", String, "The user's password"],
            ["user", JSONModel(:user), "The user to create", :body => true])
    .returns([200, :created],
             [400, :error]) \
  do
    params[:user].username = params[:user].username.downcase

    user = User.create_from_json(params[:user], :source => "local")
    DBAuth.set_password(params[:user].username, params[:password])

    created_response(user, params[:user])
  end


  Endpoint.get('/users/:username')
    .description("Get a user's details (including their current permissions)")
    .params(["username", nil, "The username of interest"])
    .returns([200, "(:user)"]) \
  do
    user = User[:username => params[:username].downcase]

    if user
      json = User.to_jsonmodel(user, :user)
      json.permissions = user.permissions
      json_response(json)
    else
      raise NotFoundException.new("User wasn't found")
    end
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
      json_response({:session => session.id, :permissions => user.permissions})
    else
      json_response({:error => "Login failed"}, 403)
    end
  end

end
