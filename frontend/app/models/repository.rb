require 'net/http'
require 'json'

class Repository < JSONModel(:repository)
    
  def save
    uri = "#{BACKEND_SERVICE_URL}/repo"

    response = Net::HTTP.post_form(URI(uri), {:repository=>self.to_json})
    JSON.parse(response.body)
  end
  
  def self.all
    uri = URI("#{BACKEND_SERVICE_URL}/repo")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
  
end
