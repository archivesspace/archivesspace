class Accession < JSONModel(:accession)

  def save(repo)
    return false if repo.blank?

    uri = URI("#{BACKEND_SERVICE_URL}/repo/#{URI.escape(repo)}/accession")
    response = Net::HTTP.post_form(uri, {:accession => self.to_json})

    response.body === "Created"
  end


  def self.find(accession_id, repo)
    uri = URI("#{BACKEND_SERVICE_URL}/repo/#{URI.escape(repo)}/accession/#{accession_id}")
    response = Net::HTTP.get(uri)

    self.from_json(response)
  end


  def resource_link
    if @resource_link.blank? then
      @resource_link = "defer"
    end
    @resource_link
  end


end
