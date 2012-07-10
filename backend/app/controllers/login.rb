class ArchivesSpaceService < Sinatra::Base

  post '/auth/user/:username/login' do
    ensure_params ["username" => {:doc => "Your username"},
                   "password" => {:doc => "Your password"}]

    user_manager = UserManager.new

    user = user_manager.get_user(params[:username])

    if user
      redirect_internal("/auth/#{user[:auth_source]}/user/#{params[:username]}/login")
    else
      json_response({:error => "Login failed"}, 403)
    end

  end

end
