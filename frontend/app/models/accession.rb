class Accession < FormtasticFauxModel
  attr_accessor :id, :repo_id, :title, :accession_id, :accession_id_0, :accession_id_1, :accession_id_2, :accession_id_3, :content_description, :condition_description, :accession_date, :create_time, :last_modified, :resource_link
  
  def initialize(attributes = {})
    @data = attributes
    super(attributes)        
  end

  def save(repo)
    return false if repo.blank?    

    uri = URI("#{BACKEND_SERVICE_URL}/repo/#{URI.escape(repo)}/accession")
    response = Net::HTTP.post_form(uri, {:accession=>@data.to_json})
    
    response.body === "Created"
  end
  
  def self.find(repo, id_0, id_1, id_2, id_3)
    uri_str = "#{BACKEND_SERVICE_URL}/repo/#{URI.escape(repo)}/accession/#{id_0}"
    unless id_1.blank? then
      uri_str += "/#{id_1}"
      unless id_1.blank? then
        uri_str += "/#{id_2}"
        unless id_1.blank? then
          uri_str += "/#{id_3}"
        end
      end              
    end
    response = Net::HTTP.get(URI(uri_str))
    self.new(JSON.parse(response))
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
    "#{accession_id_0} #{accession_id_1} #{accession_id_2} #{accession_id_3}"
  end
  
  def accession_id_for_url
    url = accession_id_0
    unless accession_id_1.blank?
      url += "/#{accession_id_1}"
      unless accession_id_2.blank?
        url += "/#{accession_id_2}"
        unless accession_id_3.blank?
          url += "/#{accession_id_3}"
        end
      end
    end
    url
  end
  
end