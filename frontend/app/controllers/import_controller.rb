class ImportController < ApplicationController

  set_access_control "update_archival_record" => [:index, :upload_select, :upload_xhr, :upload]

  skip_before_filter :verify_authenticity_token


  def index
    @importer_key = params[:importer]
  end
  
  # Index as iframe for IE 9 and lower
  
  def upload_select
    index

    render :upload_select, :layout => false
  end
  
  
  # Handle POST requests from browsers that support XKR2    
  def upload_xhr
    
    self.response_body = Enumerator.new do |y|
      run_importer do |status|
        y << "#{ASUtils.to_json(status)}---\n"
      end
    end

    self.response.headers['Last-Modified'] = Time.now.to_s
  end
  
  # Handle POST requests from IE 9 and worse

  def upload
    # no-cache required for streaming to work
    headers['Cache-Control'] = 'no-cache'
    self.response_body = Enumerator.new do |y|

      (leader, trailer) = render_to_string(:uploading, :layout => false).scan(/\A(.*)(<\/body>.*)\z/m).first

      # Emit the template up to the </body> straight away
      y << (leader + "\r\n")

      run_importer do |status|
        y << "<script>update_status(#{ASUtils.to_json(status)});</script>".html_safe + "\r\n"
      end 

      y << trailer
    end

  end


  protected
  
  def run_importer
    
    if params[:upload].blank?
      yield({'errors' => ["No file uploaded"]})
    else  
      source_file = ImportFile.new(params[:upload])    

      repo_id = params[:repo_id] ? params[:repo_id] : session[:repo_id]

      begin

        importer = get_importer(source_file, params[:importer], repo_id)
      
        importer.run_safe do |status|

          if status.has_key?('saved')
            links = status['saved'].map {|k,v| v[0]}
            links = frontend_links(links)

            status['links'] = links
            status['saved'] = status['saved'].length
          end
      
          yield status          
        end
        
        source_file.delete
        
      rescue ValidationException => e
        errors = e.errors.collect.map{|attr, err| "#{e.invalid_object.class.record_type}/#{attr} #{err.join(', ')}"}
        yield({"errors" => errors})
  
      rescue Exception => e
        Rails.logger.debug("Import Exception #{e.to_s}")
        yield({"errors" => [e.to_s]})
      end
    end
  end
  
  
  def get_importer(source_file, importer_key, repo_id)
    
    flags = []
    
    case importer_key
    when 'eac'
      importer = :eac
    when 'ead'
      importer = :ead
    when 'accession_csv'
      importer = :accessions
    when 'digital_object_csv'
      importer = :digital_objects
    when 'marcxml'
      importer = :marcxml
    when 'marcxml_subjects_and_agents'
      importer = :marcxml
      flags << 'subjects_and_agents_only'
    end


    options = {
               :repo_id => repo_id, 
               :vocab_id => '1',
               :importer => importer,
               :importer_flags => flags,
               :quiet => true,
               :input_file => source_file.path,
               :log => Rails.logger
               }
               
    ASpaceImport::Importer.create_importer(options)    

  end


  def frontend_links(links)
    result = []
    resource = nil
    links.reverse.each do |l|      
      l.sub!(/^\/repositories\/[0-9]+/, '')
      if l =~ /^\/resources\/[0-9]+$/
        resource = l 
        tree = l.sub(/^\//, '').sub(/s\//, '_')
        result << "#{resource}#tree::#{tree}"
      elsif l =~ /^\/archival_objects\//
        tree = l.sub(/^\//, '').sub(/s\//, '_')
        result << "#{resource}#tree::#{tree}"
      else
        result << l.
          sub(/\/people\//, '/agent_person/').
          sub(/\/corporate_entities\//, '/agent_corporate_entity/').
          sub(/\/software\//, '/agent_software/').
          sub(/\/families\//, '/agent_family/')

      end
    end
    root = root_url.sub(/\/$/, '')

    result.map {|l| "<a target='_blank' href='#{root}#{l}'>#{root}#{l}</a>"}
  end
end

