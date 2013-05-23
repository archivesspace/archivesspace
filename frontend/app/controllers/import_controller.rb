class ImportController < ApplicationController

  skip_before_filter :unauthorised_access
  skip_before_filter :verify_authenticity_token

  def index
    @importer_key = params[:importer]
        
    unless session[:repo_id] and session[:repo_id] > 1
      flash.now[:notice] = I18n.t("import.messages.missing_repo")
    end

  end
  
  # Index as iframe for IE 9 and lower
  
  def upload_select
    index

    render :upload_select, :layout => false
  end
  
  
  # Handle POST requests from browsers that support XKR2 
   
  def upload_xhr
    
    self.response_body = Enumerator.new do |y|
      run_importer(y) do |json_status|
        json_status + "---\n"
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

      run_importer(y) do |json_status|
        "<script>update_status(#{json_status});</script>".html_safe + "\r\n"
      end 

      y << trailer
    end

  end


  protected
  
  def run_importer(y, &block)
    
    if params[:upload].blank?
      y << block.call(ASUtils.to_json({'errors' => ["No file uploaded"]}))
    else  
      source_file = ImportFile.new(params[:upload])    

      repo_id = params[:repo_id] ? params[:repo_id] : session[:repo_id]

      begin

        importer = get_importer(source_file, params[:importer], repo_id)
      
        importer.run_safe do |status|
          
          if status.has_key?('saved')
            # status['saved'] = status['saved'].map {|k,v| v[0]}
            status['saved'] = status['saved'].length
          end
      
          y << block.call(ASUtils.to_json(status))
          
        end
        
        source_file.delete
        
      rescue ValidationException => e
        errors = e.errors.collect.map{|attr, err| "#{e.invalid_object.class.record_type}/#{attr} #{err.join(', ')}"}
        y << block.call(ASUtils.to_json({"errors" => errors}))
  
      rescue Exception => e
        Rails.logger.debug("Import Exception #{e.to_s}")
        y << block.call(ASUtils.to_json({"errors" => [e.to_s]}))
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
end

