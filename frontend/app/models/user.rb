require 'net/http'
require 'json'
require 'zlib'

class User < JSONModel(:user)

  def self.establish_session(context, backend_session, username)
    context.session[:session] = backend_session["session"]

    store_permissions(backend_session["user"]["permissions"], context)

    context.session[:user_uri] = backend_session["user"]["uri"]
    context.session[:user] = username
  end


  def self.refresh_permissions(context)
    user = self.find('current-user')

    if user
      store_permissions(user.permissions, context)
    end
  end


  def self.store_permissions(permissions, context)
    context.send(:cookies).signed[:archivesspace_permissions] = 'ZLIB:' + Zlib::Deflate.deflate(ASUtils.to_json(Permissions.pack(permissions)))
    context.session[:last_permission_refresh] = Time.now.to_i
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


  def self.become_user(context, username)
    return false if username == "admin"
    uri = JSONModel(:user).uri_for("#{username}/become-user")

    response = JSONModel::HTTP.post_form(uri)

    if response.code == '200'
      backend_session = ASUtils.json_parse(response.body)

      self.establish_session(context, backend_session, username)

      true
    else
      false
    end
  end

end
