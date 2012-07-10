require 'bcrypt'

class DBAuth

  include BCrypt

  def add_user(username, password)
    pwhash = Password.create(password)

    DB.open do |db|
      db[:auth_db].insert(:username => username,
                          :pwhash => pwhash,
                          :create_time => Time.now,
                          :last_modified => Time.now)
    end
  rescue Sequel::DatabaseError => ex
    if DB.is_integrity_violation(ex)
      raise ConflictException.new("User '#{username}' already exists.")
    end
  end


  def login(username, password)
    DB.open do |db|
      pwhash = db[:auth_db].filter(:username => username).get(:pwhash)

      return (pwhash and (Password.new(pwhash) == password))
    end
  end
end


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

    settings.db_auth.add_user(params[:username], params[:password])
  end


  get '/auth/db/user/:username' do
    "Hello, #{params[:username]}"
  end
end
