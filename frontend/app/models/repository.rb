require 'net/http'
require 'json'

class Repository < JSONModel(:repository)
    
  def save
    uri = "#{BACKEND_SERVICE_URL}/repo"
    uri += "/#{id}" unless id.blank?

    response = Net::HTTP.post_form(uri, @data)
    JSON.parse(response.body)
  end
  
  def self.all
    uri = URI("#{BACKEND_SERVICE_URL}/repo")
    response = Net::HTTP.get(uri)
    JSON.parse(response.body)
  end
  
end