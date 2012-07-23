require 'net/http'
require 'json'

class Repository
  def self.all
    uri = URI("#{BACKEND_SERVICE_URL}/repo")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
  
  def self.create(data)
    uri = URI("#{BACKEND_SERVICE_URL}/repo")
    response = Net::HTTP.post_form(uri, data)
    puts response.body       
  end
end