require_relative '../lib/auth_helpers'

class ArchivesSpaceService < Sinatra::Base

  include AuthHelpers

  configure do
    set :db_auth, DBAuth.new
    set :user_manager, UserManager.new
  end


  post '/auth/local/user/:username/login' do
    ensure_params ["username" => {:doc => "Your username"},
                   "password" => {:doc => "Your password"}]

    if settings.db_auth.login(params[:username], params[:password])
      session = create_session_for(params[:username])
      json_response({:session => session.id})
    else
      json_response({:error => "Login failed"}, 403)
    end

  end


  post '/auth/local/user/:username' do
    ensure_params ["username" => {:doc => "Username for new account"},
                   "password" => {:doc => "Password for new account"}]

    begin
      settings.user_manager.create_user(params[:username], "First", "Last", "local")
      settings.db_auth.set_password(params[:username], params[:password])
    rescue Sequel::DatabaseError => ex
      if DB.is_integrity_violation(ex)
        raise ConflictException.new("That username is already in use")
      end
    end
  end


  get '/auth/local/user/:username' do
    "Hello, #{params[:username]}"
  end
end
