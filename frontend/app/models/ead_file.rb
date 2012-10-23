require 'net/http'
require 'uri'

class EADFile 
  
  attr_accessor :file

  def initialize(resource_id)
    @resource_id = resource_id
    @file = false

    directory = Rails.root.join('tmp', 'ead')
    
    @path = File.join(directory, "#{resource_id}.xml")

    if File.exist?(@path)
      @file = @path
    end

    self
  end
  
  # Fetch the file from the backend and cache it
  
  def refresh
    url = URI.parse("#{AppConfig[:backend_url]}/repositories/#{Thread.current[:selected_repo_id]}/resource_descriptions/#{@resource_id}.xml")

    response = JSONModel::HTTP.get_response(url)

    if response.body
      File.open(@path, "wb") { |f| f.write(response.body) }
    
      if File.exist?(@path)
        @file = @path
      end
    end
    
  end
  
  def status
    if @file
      file_info = "#{File.mtime(@file)}"
      "EAD last generated at #{file_info}"
    else
      "There is no EAD for this resource: click the button to generate one."
    end
  end
  

  def delete
    File.delete(@file)  
  end
end
