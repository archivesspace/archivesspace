class ArchivesSpaceService < Sinatra::Base

  configure do
    set :db_auth, DBAuth.new
  end


  post '/auth/db/user/:username/login' do
    ensure_params ["username" => {:doc => "Your username"},
                   "password" => {:doc => "Your password"}]

    if settings.db_auth.login(params[:username], params[:password])
      session = Session.new
      session[:user] = params[:username]
      session[:login_time] = Time.now
      session.save

      json_response({:session => session.id})
    else
      json_response({:error => "Login failed"}, 403)
    end

  end


  post '/auth/db/user/:username' do
    ensure_params ["username" => {:doc => "Username for new account"},
                   "password" => {:doc => "Password for new account"}]

    settings.db_auth.set_password(params[:username], params[:password])
  end


  get '/auth/db/user/:username' do
    "Hello, #{params[:username]}"
  end
end
