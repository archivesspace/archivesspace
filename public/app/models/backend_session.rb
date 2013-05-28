require 'thread'
require 'atomic'

# All public interface threads share the same backend session.

class BackendSession
  @active_session = Atomic.new(nil)

  def self.get_active_session
    if !@active_session.value
      self.refresh_active_session
    end

    @active_session.value
  end


  def self.refresh_active_session
    username = AppConfig[:public_username]
    password = AppConfig[:public_user_secret]

    url = URI.parse(AppConfig[:backend_url] + "/users/#{username}/login")

    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data("expiring" => "false",
                          "password" => password)

    response = JSONModel::HTTP.do_http_request(url, request)

    if response.code == '200'
      auth = ASUtils.json_parse(response.body)

      @active_session.update {|val|
        auth['session']
      }
    else
      raise "Authentication to backend failed: #{response.body}"
    end
  end

end
