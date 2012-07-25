require 'net/http'

class Accession < JSONModel(:accession)
  attr_accessor :resource_link
    
  def save(repo)
    return false if repo.blank?
    
    uri = "#{BACKEND_SERVICE_URL}/repo/#{URI.escape(repo)}/accession"
    uri += "/#{id}" unless id.blank?

    response = Net::HTTP.post_form(URI(uri), {:accession=>self.to_json})
    
    JSON.parse(response.body)
  end
  
  def self.find(repo, id)
    uri_str = "#{BACKEND_SERVICE_URL}/repo/#{URI.escape(repo)}/accession/#{id}"
    response = Net::HTTP.get(URI(uri_str))
    self.from_json(response)
  end


  def resource_link
    if @resource_link.blank? then
      @resource_link = "defer"
    end
    @resource_link
  end
  
  def self.all(repo)
    uri = URI("#{BACKEND_SERVICE_URL}/repo/#{URI.escape(repo)}/accessions")
    response = Net::HTTP.get(uri)
    accessions = JSON.parse(response)
    accessions.collect {|acc| self.new(acc)}
  end
  
  def accession_id
    # display string
    str = accession_id_0
    str += "-#{accession_id_1}" unless accession_id_1.blank?
    str += "-#{accession_id_2}" unless accession_id_2.blank?
    str += "-#{accession_id_3}" unless accession_id_3.blank?
    str
  end
  
  
end
