require 'net/http'
require 'json'
require 'zlib'

class User < JSONModel(:user)

  class MailError < StandardError
  end

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
    context.send(:cookies).signed[:archivesspace_permissions] = {
      value: 'ZLIB:' + Zlib::Deflate.deflate(ASUtils.to_json(Permissions.pack(permissions))),
      httponly: true,
      same_site: :lax
    }
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


  def self.recover_password(email)
    uri = JSONModel(:user).uri_for("reset-password")

    begin
      response = JSONModel::HTTP.post_form(uri, email: email)
      message = ASUtils.json_parse(response.body)
      if response.code == '200'
        return {status: :success}
      else
        case message['error']
        when "UserMailer::MailError"
          return {status: :error, message: I18n.t("user._frontend.messages.password_reset_fail")}
        when "NotFoundException"
          return {status: :not_found, message: I18n.t("user._frontend.messages.error_not_found", email: email)}
        else
          return {status: :error, message: message['error']}
        end
      end
    rescue Exception => e
      Rails.logger.error(e)
      return { status: :error, error: I18n.t("user._frontend.messages.password_reset_fail") }
    end
  end

  def self.token_login(username, token)
    uri = JSONModel(:user).uri_for("#{username}/#{token}")

    response = JSONModel::HTTP.post_form(uri)

    if response.code == '200'
      ASUtils.json_parse(response.body)
    else
      nil
    end
  end

end
