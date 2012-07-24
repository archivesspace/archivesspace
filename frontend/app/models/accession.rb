class Accession < FormtasticFauxModel
  attr_accessor :id, :repo_id, :title, :accession_id, :accession_id_0, :accession_id_1, :accession_id_2, :accession_id_3, :content_description, :condition_description, :accession_date, :create_time, :last_modified, :resource_link
  
  def initialize(attributes = {})
    @data = attributes
    # parse accession_id
    if (attributes.has_key?('accession_id_0') || attributes.has_key?('accession_id_1') || attributes.has_key?('accession_id_2') || attributes.has_key?('accession_id_3'))
      attributes['accession_id'] = "#{attributes['accession_id_0']}#{attributes['accession_id_1']}#{attributes['accession_id_2']}#{attributes['accession_id_3']}"
    end
    super(attributes)        
  end

  def save(repo)
    return false if repo.blank?    
    
    data_to_send = @data.clone;
    data_to_send.delete('accession_id_0')
    data_to_send.delete('accession_id_1')
    data_to_send.delete('accession_id_2')
    data_to_send.delete('accession_id_3')
    data_to_send.delete('resource_link')

    uri = URI("#{BACKEND_SERVICE_URL}/repo/#{URI.escape(repo)}/accession")
    response = Net::HTTP.post_form(uri, {:accession=>data_to_send.to_json})
    
    response.body === "Created"
  end
  
  def self.find(accession_id, repo)
    uri = URI("#{BACKEND_SERVICE_URL}/repo/#{URI.escape(repo)}/accession/#{accession_id}")
    response = Net::HTTP.get(uri)
    self.new(JSON.parse(response))
  end
  
  def resource_link
    if @resource_link.blank? then
      @resource_link = "defer"
    end
    @resource_link
  end
  

  
end