require 'net/http'
require 'json'

class User < JSONModel(:user)

  def self.establish_session(session, backend_session, username)
    session[:session] = backend_session["session"]
    session[:permissions] = Permissions.pack(backend_session["user"]["permissions"])
    session[:last_permission_refresh] = Time.now.to_i
    session[:user_uri] = backend_session["user"]["uri"]
    session[:user] = username
  end


  def self.refresh_permissions(session)
    user = self.find('current-user')

    if user
      session[:permissions] = Permissions.pack(user.permissions)
      session[:last_permission_refresh] = Time.now.to_i
    end
  end


  def self.login(username, password)
    uri = JSONModel(:user).uri_for("#{username}/login")

    response = JSONModel::HTTP.post_form(uri, :password => password)

    if response.code == '200'
      ASUtils.json_parse(response.body)
    else
      nil
    end
  end

end
