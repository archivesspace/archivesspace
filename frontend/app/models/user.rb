require 'net/http'
require 'json'

class User
  def initialize(json)
    @data = JSON.parse(json)
  end
  
  def self.login(username, password)
      login_uri = URI("#{BACKEND_SERVICE_URL}/auth/user/#{username}/login")
      response = Net::HTTP.post_form(login_uri, :password=>password)
      JSON.parse(response.body)
  end   
end