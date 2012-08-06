class ArchivesSpaceService < Sinatra::Base

  Endpoint
    .method(:post)
    .uri('/auth/user/:username/login')
    .params(["username", nil, "Your username"],
            ["password", nil, "Your password"])
    .returns([200, "OK"]) \
  do
    user_manager = UserManager.new

    user = user_manager.get_user(params[:username])

    if user
      redirect_internal("/auth/#{user[:auth_source]}/user/#{params[:username]}/login")
    else
      json_response({:error => "Login failed"}, 403)
    end

  end

end
