class DBAuth
  def initialize
  end

  def login(username, password)
    DB.open do |db|
      puts "Do something clever with #{db.inspect} here"
    end

    return true
  end
end


class ArchivesSpaceService < Sinatra::Base

  post '/auth/db/login' do
    ensure_params ["username" => {:doc => "Your username"},
                   "password" => {:doc => "Your password"}]

    db_auth = DBAuth.new

    if db_auth.login(params[:username], params[:password])
      session = Session.new
      session[:user] = params[:username]
      session[:login_time] = Time.now
      session.save

      json_response({:session => session.id})
    else
      [403, {}, ["No dice"]]
    end

  end


  get '/auth/db/user/:username' do
    "Hello, #{params[:username]}"
  end
end
